#!/bin/sh
# osTicket rootless entrypoint: render runtime config from env, do a one-time idempotent
# install, then hand off to the web supervisor (nginx + php-fpm); cron runs as a separate
# CronJob. Runs unprivileged by default (uid 1000); honors PUID/PGID only if started as root.
set -eu

OST_ROOT=/var/www/html
RUN=/run/osticket

# ── PUID/PGID — opt-in, only when started as root (docker-compose parity). ───────────
# The rootless default (non-root start) skips this entirely. Arbitrary runAsUser also
# works without this, because writable dirs are group-0 + group-writable (set at build).
if [ "$(id -u)" = "0" ]; then
    PUID="${PUID:-1000}"; PGID="${PGID:-1000}"
    # Only the writable runtime dir needs (re)owning; the app tree (incl. include/) is
    # read-only, and ost-config.php is symlinked into ${RUN}.
    chown -R "${PUID}:${PGID}" "${RUN}" 2>/dev/null || true
    exec su-exec "${PUID}:${PGID}" "$0" "$@"
fi

# ── Docker / file-based secret injection (the *_FILE convention). ─────────────────────
# Each KNOWN secret may be supplied as <VAR>_FILE pointing at a file (Docker secrets at
# /run/secrets/*, or a bind-mount), so it never sits in the container env or a compose
# file. (Kubernetes injects via secretKeyRef→env.) NO eval and NO dynamic var-name
# building: the explicit call sites below ARE the entire, auditable file-read surface, and
# a hostile env value can only ever name a *path* — never become a command. File value
# wins; single-line (CR/LF stripped); runs before anything below reads a secret.
_load_secret() {  # $1 = var name (a literal here), $2 = file path from <VAR>_FILE
    # Regular file only — reject FIFOs / device nodes / dirs (also avoids a blocking read).
    [ -n "$2" ] && [ -f "$2" ] && [ -r "$2" ] || return 0
    _secret="$(tr -d '\r\n' < "$2")"
    export "$1=$_secret"
    echo "[entrypoint] loaded $1 from ${1}_FILE (file-based secret)"
}
_load_secret DB_PASS        "${DB_PASS_FILE:-}"
_load_secret INSTALL_SECRET "${INSTALL_SECRET_FILE:-}"
_load_secret ADMIN_PASS     "${ADMIN_PASS_FILE:-}"
_load_secret SMTP_PASSWORD  "${SMTP_PASSWORD_FILE:-}"
_load_secret SMTP_PASS      "${SMTP_PASS_FILE:-}"
unset _secret

# ── SMTP password: canonical SMTP_PASS, fall back to SMTP_PASSWORD (old deployments). ─
SMTP_PASS="${SMTP_PASS:-${SMTP_PASSWORD:-}}"; export SMTP_PASS

# ── PHP runtime tunables → /run (scanned via PHP_INI_SCAN_DIR). conf.d stays read-only. ─
mkdir -p "${RUN}/php"
cat > "${RUN}/php/zz-runtime.ini" <<EOF
memory_limit = ${PHP_MEMORY_LIMIT}
upload_max_filesize = ${PHP_UPLOAD_MAX_SIZE}
post_max_size = ${PHP_UPLOAD_MAX_SIZE}
date.timezone = ${TZ}
EOF

# ── Render nginx config with the chosen listen port + create writable temp dirs. ─────
mkdir -p "${RUN}/nginx/client_body" "${RUN}/nginx/proxy" "${RUN}/nginx/fastcgi" \
         "${RUN}/nginx/uwsgi" "${RUN}/nginx/scgi"
sed "s/__HTTP_PORT__/${HTTP_PORT}/" /etc/nginx/nginx.conf > "${RUN}/nginx.conf"

db() { mariadb -h"${DB_HOST}" -P"${DB_PORT}" -u"${DB_USER}" -p"${DB_PASS}" "$@"; }

# ── Wait for the database. ───────────────────────────────────────────────────────────
echo "[entrypoint] waiting for database ${DB_HOST}:${DB_PORT} ..."
i=0; until db -e "SELECT 1" "${DB_NAME}" >/dev/null 2>&1; do
    i=$((i+1)); [ "$i" -gt 60 ] && { echo "[entrypoint] DB not reachable, giving up"; exit 1; }
    sleep 2
done

# ── Install / config refresh (idempotent + migration-safe across replicas). ──────────
# install-seed.php is the single decision point — run it on EVERY boot, NOT gated by an
# entrypoint-side "already installed?" check (which would skip the script and leave a
# fresh container with no ost-config.php → setup wizard). It connects, ALWAYS (re)writes
# ost-config.php from env (so an existing DB / replica restart / live migration gets the
# env DB creds + the shared SECRET_SALT and serves the real app), and drives osTicket's
# OWN Installer (schema + admin with proper password hashing + default config/emails)
# ONLY when the DB is fresh. The encryption secret comes from INSTALL_SECRET so every
# replica shares one SECRET_SALT.
echo "[entrypoint] running install-seed (refreshes config; installs only if DB is fresh) ..."
php /var/www/install-seed.php
echo "[entrypoint] install-seed complete."

exec "$@"
