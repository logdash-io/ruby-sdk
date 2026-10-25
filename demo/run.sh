#!/bin/sh
# Installs the logdash gem from RubyGems, LOGDASH_VERSION or the latest, sends logs and a metric with it,
# and reads them back from the API. Needs Docker, curl and jq.
set -eu

: "${LOGDASH_API_KEY:?must be the ingest key of the SDK smoke tests domain}"
api=https://api.logdash.io
seed=$(date +%s) # new every run, so the read-back finds what this run sent and nothing older

# RubyGems serves a version a little after its push, so installing one retries for up to 10 minutes.
attempt=1
until docker build --no-cache --build-arg LOGDASH_VERSION="${LOGDASH_VERSION:-}" -t logdash-demo -f demo/Dockerfile .; do
  if [ -z "${LOGDASH_VERSION:-}" ] || [ "$attempt" -ge 20 ]; then exit 1; fi
  echo "logdash $LOGDASH_VERSION does not install yet, retrying in 30s"
  attempt=$((attempt + 1))
  sleep 30
done

docker run --rm -e LOGDASH_API_KEY -e LOGDASH_SEED="$seed" logdash-demo

# A read-only personal key restricted to the smoke-test domain, which whoami names.
auth="Authorization: Bearer ${LOGDASH_PERSONAL_API_KEY:-}"
if ! whoami=$(curl -sS --fail-with-body -H "$auth" "$api/personal-api-keys/whoami") ||
  ! domain=$(printf '%s' "$whoami" | jq -er '.access | select(.kind == "clusters" and (.ids | length) == 1) | .ids[0]'); then
  access=$(printf '%s' "$whoami" | jq -c '.access' 2>/dev/null || echo 'no access in the response')
  echo "LOGDASH_PERSONAL_API_KEY must be a personal API key restricted to the SDK smoke tests domain. Its access: $access" >&2
  exit 1
fi

# Logs and metrics show up a few seconds after they arrive.
levels='["debug", "error", "http", "info", "silly", "verbose", "warning"]'
logs='' metrics='' attempt=1
until
  logs=$(curl -sS --fail-with-body -G -H "$auth" --data-urlencode "searchString=$seed" -d apps=ruby-sdk -d limit=100 \
    "$api/clusters/$domain/logs") &&
    metrics=$(curl -sS --fail-with-body -H "$auth" "$api/clusters/$domain/metrics") &&
    printf '%s' "$logs" | jq -e --arg m "smoke test $seed" --argjson levels "$levels" \
      '[.[] | select(.app == "ruby-sdk" and .message == $m) | .level] | unique == $levels' >/dev/null &&
    printf '%s' "$metrics" | jq -e --argjson v "$((seed + 1))" \
      'any(.[]; .app == "ruby-sdk" and .name == "demo_users" and .value == $v)' >/dev/null
do
  if [ "$attempt" -ge 30 ]; then
    echo "Did not read back a log of every level and demo_users = $((seed + 1)); both keys must be of one domain." >&2
    echo "Logs: $logs" >&2
    echo "Metrics: $metrics" >&2
    exit 1
  fi
  attempt=$((attempt + 1))
  sleep 2
done
echo "Read back a log of every level and demo_users = $((seed + 1))"
