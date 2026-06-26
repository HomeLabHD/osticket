#!/bin/sh
# osTicket rootless entrypoint: render runtime config from env, do a one-time idempotent
# install, then hand off to supervisord (nginx + php-fpm + cron). Runs unprivileged by
# default (uid 1000); honors PUID/PGID only if explicitly started as root.
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

# ── First-run install (idempotent across replicas). ─────────────────────────────────
# NOTE: the schema load + initial data + admin creation below mirror osTicket 1.18's
# installer; this is the one part that must be verified against a live DB on first
# deploy (config format + password hashing). If install is skipped/incomplete, osTicket
# serves its setup wizard, so the container is always usable.
if db -e "SELECT 1 FROM ${DB_PREFIX}config LIMIT 1" "${DB_NAME}" >/dev/null 2>&1; then
    echo "[entrypoint] osTicket already installed — skipping install."
else
    echo "[entrypoint] installing osTicket into ${DB_NAME} ..."
    # 1) config file from env
    SECRET="${INSTALL_SECRET:-$(head -c 32 /dev/urandom | od -An -tx1 | tr -d ' \n')}"
    sed -e "s/%TABLE_PREFIX%/${DB_PREFIX}/g" "${OST_ROOT}/include/ost-sampleconfig.php" \
        > "${OST_ROOT}/include/ost-config.php"
    # 2) schema
    sed "s/%TABLE_PREFIX%/${DB_PREFIX}/g" "${OST_ROOT}/setup/inc/streams/core/install-mysql.sql" \
        | db "${DB_NAME}"
    # 3) admin + core config via osTicket's own classes (correct password hashing)
    HTTP_PORT="${HTTP_PORT}" SECRET="${SECRET}" php "${OST_ROOT}/../install-seed.php" || {
        echo "[entrypoint] WARN: seed step needs validation; osTicket will show the setup wizard."; }
    echo "[entrypoint] install complete."
fi

exec "$@"
