# osTicket — rootless, self-owned image on a stock, current PHP base. Web tier
# (nginx + php-fpm) under tini, but UNPRIVILEGED: runs as uid 1000 (arbitrary-UID capable),
# nginx binds 8080 (not 80), nothing needs root at runtime. osTicket cron runs as a
# separate Kubernetes CronJob (see docs/k8s/cronjob.yaml), NOT in the web container.
#
# PHP pinned to 8.3 ON PURPOSE: osTicket needs the imap extension, which was removed from
# PHP core in 8.4 (8.4+ breaks `docker-php-ext-install imap`). The moving 8.3 tag
# auto-patches within 8.3 each build; the dep updater must not bump the minor.
FROM php:8.3.31-fpm-alpine

ARG OSTICKET_VERSION=1.18.4
ARG OSTICKET_PLUGINS_VERSION=develop
ARG PUID=1000
ARG PGID=1000

LABEL org.opencontainers.image.title="osticket" \
      org.opencontainers.image.description="osTicket support ticketing — rootless, php-fpm+nginx, self-built" \
      org.opencontainers.image.source="https://github.com/HomeLabHD/osticket"

# ── PHP extensions + nginx + tini ───────────────────────────────────────────────
# Runtime libs and tools are kept; the compiler toolchain (.build-deps) is installed
# and removed in the same layer, so the image carries the .so's, not the build chain.
# tini is a tiny init/reaper (PID1): reaps zombies + forwards signals, fully rootless.
RUN set -eux; \
    apk add --no-cache \
        nginx tini mariadb-client tzdata curl su-exec \
        c-client freetype gettext icu-libs krb5-libs libintl libjpeg-turbo libldap libpng libzip oniguruma; \
    apk add --no-cache --virtual .build-deps \
        $PHPIZE_DEPS freetype-dev gettext-dev icu-dev imap-dev krb5-dev \
        libjpeg-turbo-dev libpng-dev libzip-dev oniguruma-dev openldap-dev openssl-dev; \
    docker-php-ext-configure gd --with-freetype --with-jpeg; \
    docker-php-ext-configure imap --with-imap --with-imap-ssl --with-kerberos; \
    docker-php-ext-install -j"$(nproc)" gd gettext imap intl ldap mbstring mysqli opcache pdo_mysql zip; \
    apk del .build-deps

# ── osTicket application (the release zip's upload/ dir is the deployable webroot) ──
RUN set -eux; \
    curl -fsSL -o /tmp/ost.zip \
        "https://github.com/osTicket/osTicket/releases/download/v${OSTICKET_VERSION}/osTicket-v${OSTICKET_VERSION}.zip"; \
    mkdir -p /usr/src/ost; unzip -q /tmp/ost.zip -d /usr/src/ost; \
    SRC=/usr/src/ost/upload; [ -d "$SRC" ] || SRC=/usr/src/ost; \
    mkdir -p /var/www/html; cp -a "$SRC"/. /var/www/html/; \
    rm -rf /usr/src/ost /tmp/ost.zip

# ── Plugins: official set (hydrated → bundles deps, incl LDAP/OAuth/storage) + community ──
RUN set -eux; \
    apk add --no-cache --virtual .plugins git composer; \
    PLUGINS=/var/www/html/include/plugins; mkdir -p "$PLUGINS"; \
    git clone --depth 1 -b "${OSTICKET_PLUGINS_VERSION}" \
        https://github.com/osTicket/osTicket-plugins /usr/src/osticket-plugins; \
    ( cd /usr/src/osticket-plugins && php -d phar.readonly=0 make.php hydrate ) \
        || echo "WARN: official plugin hydrate incomplete — source still bundled"; \
    rm -rf /usr/src/osticket-plugins/.git; \
    cp -a /usr/src/osticket-plugins/. "$PLUGINS/"; \
    rm -rf /usr/src/osticket-plugins; \
    for spec in \
        "clonemeagain/osticket-plugin-archiver:archiver" \
        "clonemeagain/attachment_preview:attachment-preview" \
        "clonemeagain/plugin-autocloser:auto-closer" \
        "bkonetzny/osticket-fetch-note:fetch-note" \
        "clonemeagain/OSTicket-plugin-field-radiobuttons:field-radiobuttons" \
        "clonemeagain/osticket-plugin-mentioner:mentioner" \
        "philbertphotos/osticket-multildap-auth:multi-ldap" \
        "clonemeagain/osticket-plugin-preventautoscroll:prevent-autoscroll" \
        "clonemeagain/plugin-fwd-rewriter:rewriter" \
        "clonemeagain/osticket-slack:slack" \
        "ipavlovi/osTicket-Microsoft-Teams-plugin:teams"; \
    do \
        repo="${spec%%:*}"; dst="${spec##*:}"; \
        git clone --depth 1 "https://github.com/${repo}" "$PLUGINS/${dst}" \
            || { echo "WARN: community plugin ${repo} unavailable — skipped"; continue; }; \
        rm -rf "$PLUGINS/${dst}/.git"; \
    done; \
    apk del .plugins

# ── Non-root user + all writable paths chowned at BUILD time (no runtime chown) ─────
RUN set -eux; \
    addgroup -g ${PGID} osticket; \
    adduser -u ${PUID} -G osticket -D -H -s /sbin/nologin osticket; \
    # Drop the stock php-fpm pool (it sets user=www-data, which a non-root master can't setuid to).
    rm -f /usr/local/etc/php-fpm.d/www.conf /usr/local/etc/php-fpm.d/www.conf.default; \
    mkdir -p /run/osticket /var/lib/nginx/tmp; \
    # Rootless + arbitrary-uid (OpenShift pattern): own writable paths by uid 1000 AND
    # group 0, group-writable — so the image runs as 1000 by default OR any runAsUser
    # (gid 0) with no root and no runtime chown. osTicket is stateless, so this covers all.
    # Scope is narrow ON PURPOSE: generated config + runtime state/temp/logs only — NOT
    # the PHP config tree (mutable config dirs are a bigger trust surface). PHP runtime
    # overrides are rendered into /run/osticket/php instead (see PHP_INI_SCAN_DIR).
    for d in /var/www/html/include /run/osticket /var/lib/nginx; do \
        chown -R ${PUID}:0 "$d"; chmod -R g+rwX "$d"; \
    done

# ── Configs (own copies, not vendor scaffolding) ───────────────────────────────────
COPY rootfs/nginx.conf            /etc/nginx/nginx.conf
COPY rootfs/php-fpm-osticket.conf /usr/local/etc/php-fpm.d/zz-osticket.conf
COPY rootfs/opcache.ini           /usr/local/etc/php/conf.d/opcache.ini
COPY rootfs/docker-entrypoint.sh  /usr/local/bin/docker-entrypoint.sh
COPY rootfs/web-run.sh            /usr/local/bin/web-run.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh /usr/local/bin/web-run.sh

# Runtime defaults — all overridable at deploy time. See docs/Environment_Variables.md.
# HTTP_PORT defaults to 8080 because the container is rootless (uid 1000) and an
# unprivileged process cannot bind <1024; serving on 80 requires root or NET_BIND_SERVICE.
# PHP scans the read-only build configs (extensions + opcache) AND the writable /run
# dir where the entrypoint renders runtime tunables — keeps conf.d immutable.
ENV PHP_INI_SCAN_DIR=/usr/local/etc/php/conf.d:/run/osticket/php \
    HTTP_PORT=8080 \
    DB_PORT=3306 \
    DB_NAME=osticket \
    DB_PREFIX=ost_ \
    SMTP_PORT=587 \
    SMTP_TLS=1 \
    ADMIN_FIRSTNAME=Admin \
    ADMIN_LASTNAME=User \
    PHP_MEMORY_LIMIT=256M \
    PHP_UPLOAD_MAX_SIZE=25M \
    TZ=UTC

USER ${PUID}:${PGID}
WORKDIR /var/www/html
EXPOSE 8080
HEALTHCHECK --interval=30s --timeout=5s --start-period=45s \
    CMD curl -fsS -o /dev/null "http://127.0.0.1:${HTTP_PORT}/scp/login.php" || exit 1
ENTRYPOINT ["tini", "--", "docker-entrypoint.sh"]
CMD ["web-run.sh"]
