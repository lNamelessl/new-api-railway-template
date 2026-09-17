#!/bin/sh
# Railway entrypoint wrapper for new-api.
#
# 1. Waits for MySQL and Redis to accept TCP connections (Railway starts all
#    services in parallel; new-api exits fatally if the DB is not reachable at
#    boot, so we gate the process on its dependencies).
# 2. Provides code defaults for non-secret app settings so the template needs
#    zero deploy-form prompts. Any variable the operator sets explicitly wins.

set -eu

log() { echo "[entrypoint] $*"; }

wait_for() {
    host="$1"; port="$2"; name="$3"; tries=0
    while ! nc -z -w 2 "$host" "$port" 2>/dev/null; do
        tries=$((tries + 1))
        if [ "$tries" -gt 150 ]; then
            log "ERROR: $name at $host:$port not reachable after 300s"
            exit 1
        fi
        sleep 2
    done
    log "$name reachable at $host:$port"
}

: "${MYSQL_HOST:=${SQL_DSN_HOST:-}}"
: "${REDIS_HOST:=${REDIS_CONN_STRING_HOST:-}}"

if [ -n "$MYSQL_HOST" ]; then
    log "waiting for MySQL at $MYSQL_HOST:3306 ..."
    wait_for "$MYSQL_HOST" 3306 "MySQL"
else
    log "MYSQL_HOST not set; skipping MySQL wait (SQLite mode?)"
fi

if [ -n "$REDIS_HOST" ]; then
    log "waiting for Redis at $REDIS_HOST:6379 ..."
    wait_for "$REDIS_HOST" 6379 "Redis"
else
    log "REDIS_HOST not set; skipping Redis wait"
fi

# Code defaults for non-secret settings (operator-provided values win).
export TZ="${TZ:-UTC}"
export SYNC_FREQUENCY="${SYNC_FREQUENCY:-60}"
export BATCH_UPDATE_ENABLED="${BATCH_UPDATE_ENABLED:-true}"
export MEMORY_CACHE_ENABLED="${MEMORY_CACHE_ENABLED:-true}"
export ERROR_LOG_ENABLED="${ERROR_LOG_ENABLED:-true}"
export STREAMING_TIMEOUT="${STREAMING_TIMEOUT:-300}"

log "starting new-api on port 3000 ..."
exec /new-api
