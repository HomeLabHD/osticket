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
    chown -R "${PUID}:${PGID}" "${RUN}" "${OST_ROOT}/include" 2>/dev/null || true
    exec su-exec "${PUID}:${PGID}" "$0" "$@"
fi

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
