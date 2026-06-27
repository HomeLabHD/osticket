#!/bin/sh
# Web tier launcher — tini (PID1) runs this. Launch the two web daemons (php-fpm + nginx)
# as background children; if EITHER exits, tear down the other and exit non-zero so
# Kubernetes/Docker restarts the pod. Fail-fast over hidden in-place restart: in a
# replicated k8s Deployment a dead daemon means a bad replica the orchestrator should
# replace, not paper over. No in-container cron — that's a separate CronJob.
# Daemon invocations mirror the old supervisord.conf exactly.
set -eu

# Forward shutdown signals to the children for a clean stop.
trap 'kill -TERM "$php_pid" "$nginx_pid" 2>/dev/null' TERM INT

php-fpm -F & php_pid=$!
nginx -c /run/osticket/nginx.conf -g 'daemon off;' & nginx_pid=$!

# Watch both; the moment either dies, stop waiting.
while kill -0 "$php_pid" 2>/dev/null && kill -0 "$nginx_pid" 2>/dev/null; do
    sleep 2
done

# One died — tear the other down and signal failure so the pod restarts.
kill -TERM "$php_pid" "$nginx_pid" 2>/dev/null || true
exit 1
