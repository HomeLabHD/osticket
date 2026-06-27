<?php
/**
 * install-seed.php — headless, env-driven osTicket installer.
 *
 * Drives osTicket's OWN Installer class (setup_hidden/inc/class.installer.php), the
 * same code the web setup wizard uses, so the result is a fully-installed system
 * (schema + admin staff WITH osTicket's password hashing + default config/emails) —
 * never the setup wizard. Adapted for this rootless image (uid 1000, no chown) and
 * multi-replica deploys (the encryption secret comes from INSTALL_SECRET so every
 * replica shares one SECRET_SALT).
 *
 * Flow: env -> $vars -> connect & check idempotency -> write ost-config.php from the
 * 1.18 sample with the real placeholders filled (incl. our secret, OSTINSTALLED=TRUE)
 * -> $installer->install($vars) -> (best-effort) seed default email SMTP from SMTP_*.
 *
 * Exit codes: 0 = installed (or already installed), non-zero = real failure.
 */

error_reporting(E_ALL & ~E_NOTICE & ~E_WARNING & ~E_DEPRECATED);

define('OST_ROOT', '/var/www/html');
define('SETUP_HIDDEN', OST_ROOT . '/setup_hidden');
define('OSTICKET_CONFIGFILE', OST_ROOT . '/include/ost-config.php');
define('OSTICKET_SAMPLECONFIG', OST_ROOT . '/include/ost-sampleconfig.php');

function seed_log($m) { fwrite(STDOUT, "[install-seed] $m\n"); }
function seed_die($m) { fwrite(STDERR, "[install-seed] ERROR: $m\n"); exit(1); }

function env($k, $default = null) {
    $v = getenv($k);
    return ($v === false || $v === '') ? $default : $v;
}

// ── Gather config from env ─────────────────────────────────────────────────────────
$dbhost = env('DB_HOST') ?: seed_die('DB_HOST is required');
$dbport = env('DB_PORT', '3306');
$dbname = env('DB_NAME', 'osticket');
$dbuser = env('DB_USER') ?: seed_die('DB_USER is required');
$dbpass = env('DB_PASS', '');
$prefix = env('DB_PREFIX', 'ost_');

// ── Install secret: MUST be shared across replicas (it is the encryption key). ──────
$secret = env('INSTALL_SECRET');
if ($secret === null) {
    $secret = substr(bin2hex(random_bytes(32)), 0, 32);
    seed_log('WARNING: INSTALL_SECRET is unset — generated an ephemeral secret. This is');
    seed_log('WARNING: fine for a single replica, but MULTI-REPLICA deploys MUST set a');
    seed_log('WARNING: fixed INSTALL_SECRET (>=32 chars) so all replicas share SECRET_SALT.');
}

// Define SECRET_SALT now (before the Installer runs) so any credential encryption done
// during/after install uses the SAME key that ost-config.php pins for the running app.
// Otherwise the Installer falls back to md5(prefix.admin_email) and runtime crypto breaks.
if (!defined('SECRET_SALT'))
    define('SECRET_SALT', $secret);

$vars = array(
    'name'        => env('INSTALL_NAME', 'Helpdesk'),
    'email'       => env('INSTALL_EMAIL') ?: seed_die('INSTALL_EMAIL is required'),
    'url'         => env('INSTALL_URL', 'http://localhost'),
    'lang_id'     => env('INSTALL_LANG', 'en_US'),
    'timezone'    => env('TZ', 'UTC'),
    'fname'       => env('ADMIN_FIRSTNAME', 'Admin'),
    'lname'       => env('ADMIN_LASTNAME', 'User'),
    'admin_email' => env('ADMIN_EMAIL') ?: seed_die('ADMIN_EMAIL is required'),
    'username'    => env('ADMIN_USER') ?: seed_die('ADMIN_USER is required'),
    'passwd'      => env('ADMIN_PASS') ?: seed_die('ADMIN_PASS is required'),
    'passwd2'     => env('ADMIN_PASS'),
    'prefix'      => $prefix,
    'dbhost'      => $dbhost,
    'dbname'      => $dbname,
    'dbuser'      => $dbuser,
    'dbpass'      => $dbpass,
);

// ── Minimal $_SERVER so the CLI bootstrap doesn't choke / emit garbage URLs. ─────────
$_SERVER['HTTP_HOST']      = parse_url($vars['url'], PHP_URL_HOST) ?: 'localhost';
$_SERVER['REMOTE_ADDR']    = '127.0.0.1';
$_SERVER['REQUEST_METHOD'] = 'GET';
$_SERVER['PHP_SELF']       = '/setup/install.php';
$_SERVER['SCRIPT_NAME']    = '/setup/install.php';
$_SERVER['HTTP_ACCEPT_LANGUAGE'] = env('LANGUAGE', 'en-us');

// Pin the helpdesk URL the Installer records (setup.inc.php would otherwise derive it
// from HTTP_HOST). Define BEFORE setup.inc.php to win the define() race.
define('URL', $vars['url']);

if (!is_file(SETUP_HIDDEN . '/setup.inc.php'))
    seed_die('setup_hidden/setup.inc.php not found — is the image built with setup renamed?');

// ── Bring up osTicket's setup bootstrap + the Installer class. ──────────────────────
chdir(SETUP_HIDDEN);
require SETUP_HIDDEN . '/setup.inc.php';
require_once INC_DIR . 'class.installer.php';

// Non-standard DB port goes through mysqli's default-port ini (osTicket's db_connect
// does not take a port argument).
ini_set('mysqli.default_port', $dbport);

$installer = new Installer(OSTICKET_CONFIGFILE);

// ── Idempotency: if the config table already exists, this DB is installed. ──────────
seed_log("connecting to mysql://{$dbuser}@{$dbhost}:{$dbport}/{$dbname}");
if (!db_connect($dbhost, $dbuser, $dbpass))
    seed_die('unable to connect to MySQL: ' . db_connect_error());

if (db_select_database($dbname) && db_query('SELECT 1 FROM `' . $prefix . 'config` LIMIT 1', false)) {
    seed_log("already installed (found {$prefix}config) — nothing to do.");
    exit(0);
}

// ── Write ost-config.php from the 1.18 sample with the real placeholders filled. ────
seed_log('writing ' . OSTICKET_CONFIGFILE . ' from sample');
// NB: do NOT name this global $cfg — osTicket's Installer/i18n use a global $cfg
// (OsticketConfig); a string in that slot crashes Internationalization::__construct.
$cfgtext = @file_get_contents(OSTICKET_SAMPLECONFIG);
if ($cfgtext === false)
    seed_die('cannot read sample config: ' . OSTICKET_SAMPLECONFIG);

// Escape values destined for single-quoted PHP string literals in the config file.
$q = function ($s) { return str_replace(array('\\', "'"), array('\\\\', "\\'"), (string) $s); };

$cfgtext = strtr($cfgtext, array(
    "define('OSTINSTALLED',FALSE);" => "define('OSTINSTALLED',TRUE);",
    '%ADMIN-EMAIL'   => $q($vars['admin_email']),
    '%CONFIG-DBHOST'  => $q($vars['dbhost']),
    '%CONFIG-DBNAME'  => $q($vars['dbname']),
    '%CONFIG-DBUSER'  => $q($vars['dbuser']),
    '%CONFIG-DBPASS'  => $q($vars['dbpass']),
    '%CONFIG-PREFIX'  => $q($vars['prefix']),
    '%CONFIG-SIRI'    => $q($secret),
));

if (@file_put_contents(OSTICKET_CONFIGFILE, $cfgtext) === false)
    seed_die('cannot write config file (is include/ group-writable?): ' . OSTICKET_CONFIGFILE);
@chmod(OSTICKET_CONFIGFILE, 0640);

// ── Run osTicket's own installer (schema + admin + defaults). ───────────────────────
seed_log('running osTicket Installer (schema + admin user + defaults)…');
if (!$installer->install($vars)) {
    seed_log('install FAILED:');
    foreach ($installer->getErrors() as $k => $e)
        fwrite(STDERR, "  - " . (is_string($k) ? "$k: " : '') . (is_array($e) ? implode('; ', $e) : $e) . "\n");
    exit(1);
}
seed_log('osTicket installed: schema loaded, admin "' . $vars['username'] . '" created.');

// ── Best-effort: seed default system email outbound SMTP from SMTP_* env. ───────────
// osTicket sends mail via the per-email SMTP account stored in the DB (no msmtp). This
// is guarded: any failure here is logged but never fails the install — the system is
// already usable and SMTP can be set in the admin UI.
$smtp_host = env('SMTP_HOST');
if ($smtp_host !== null) {
    try {
        seed_seed_smtp($vars, $smtp_host);
    } catch (\Throwable $ex) {
        seed_log('WARNING: SMTP seed skipped: ' . $ex->getMessage());
    }
}

seed_log('done.');
exit(0);

/**
 * Configure outbound SMTP on the default system email, using osTicket's own
 * SmtpAccount model + the legacy "basic" auth credential store (encrypted with
 * SECRET_SALT, exactly as the admin UI does). Active only when host is present.
 */
function seed_seed_smtp($vars, $smtp_host) {
    $smtp_port = (int) env('SMTP_PORT', '587');
    $smtp_user = env('SMTP_USER');
    $smtp_pass = env('SMTP_PASS') ?: env('SMTP_PASSWORD'); // SMTP_PASS wins, fall back
    $smtp_from = env('SMTP_FROM', $vars['email']);
    $smtp_tls  = env('SMTP_TLS', '1');
    $tls_on    = !in_array(strtolower((string) $smtp_tls), array('0', 'false', 'off', 'no', ''), true);

    // The default system email the Installer created from INSTALL_EMAIL.
    $eid = Email::getIdByEmail($smtp_from) ?: Email::getIdByEmail($vars['email']);
    $email = $eid ? Email::lookup($eid) : null;
    if (!$email) { seed_log('WARNING: SMTP seed: default system email not found'); return; }

    $encryption = !$tls_on ? 'NONE' : (($smtp_port === 465) ? 'SSL' : 'AUTO');

    $smtp = $email->getSmtpAccount(true); // autoinit a fresh SmtpAccount for this email
    $smtp->set('host', $smtp_host);
    $smtp->set('port', $smtp_port);
    $smtp->set('protocol', 'SMTP');
    $smtp->set('encryption', $encryption);
    $smtp->set('active', $smtp_user ? 1 : 0);
    $smtp->set('auth_bk', $smtp_user ? 'basic' : 'none');
    if (!$smtp->save()) { seed_log('WARNING: SMTP seed: could not save smtp account'); return; }

    // Store basic-auth credentials the way EmailAccount::updateBasicAuthCredentials does:
    // username + password encrypted with SECRET_SALT, namespaced per email/account.
    if ($smtp_user) {
        $ns  = sprintf('email.%d.account.%d', $email->getId(), $smtp->getId());
        $enc = Crypto::encrypt((string) $smtp_pass, SECRET_SALT, md5($smtp_user . $ns));
        $c   = new EmailAccountConfig($ns);
        $c->updateInfo(array('username' => $smtp_user, 'passwd' => $enc));
    }
    seed_log("SMTP seeded on <{$email->getEmail()}> → {$smtp_host}:{$smtp_port} ({$encryption})");
}
