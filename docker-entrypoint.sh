#!/bin/sh
set -e

# Ensure the fpm worker user owns the writable config/include path — covers the
# case where a volume is mounted over it at deploy. No-op under a non-root
# securityContext. Static app code stays as-built.
if [ "$(id -u)" = "0" ]; then
    chown -R www-data:www-data /var/www/html/include 2>/dev/null || true
fi

exec "$@"
