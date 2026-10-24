#!/bin/sh
# Installs the logdash gem from RubyGems, LOGDASH_VERSION or the latest, sends logs and a metric with it,
# and reads them back from the API. Needs Docker, curl and jq.
set -eu

: "${LOGDASH_API_KEY:?must be the ingest key of the smoke-test project}"
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

# A read-only personal key restricted to the smoke-test project, which whoami names.
auth="Authorization: Bearer ${LOGDASH_PERSONAL_API_KEY:-}"
if ! whoami=$(curl -sS --fail-with-body -H "$auth" "$api/personal-api-keys/whoami") ||
  ! project=$(printf '%s' "$whoami" | jq -er '.access | select(.kind == "projects" and (.ids | length) == 1) | .ids[0]'); then
  echo "LOGDASH_PERSONAL_API_KEY must be a personal API key restricted to the smoke-test project. whoami: $whoami" >&2
  exit 1
fi

# Logs and metrics show up a few seconds after they arrive.
levels='["debug", "error", "http", "info", "silly", "verbose", "warning"]'
logs='' metrics='' attempt=1
until
  logs=$(curl -sS --fail-with-body -G -H "$auth" --data-urlencode "searchString=$seed" -d limit=100 \
    "$api/projects/$project/logs/v2") &&
    metrics=$(curl -sS --fail-with-body -H "$auth" "$api/projects/$project/metrics") &&
    printf '%s' "$logs" | jq -e --arg m "smoke test $seed" --argjson levels "$levels" \
      '[.[] | select(.message == $m) | .level] | unique == $levels' >/dev/null &&
    printf '%s' "$metrics" | jq -e --argjson v "$((seed + 1))" \
      'any(.[]; .name == "demo_users" and .value == $v)' >/dev/null
do
  if [ "$attempt" -ge 30 ]; then
    echo "Did not read back a log of every level and demo_users = $((seed + 1)); both keys must be of one project." >&2
    echo "Logs: $logs" >&2
    echo "Metrics: $metrics" >&2
    exit 1
  fi
  attempt=$((attempt + 1))
  sleep 2
done
echo "Read back a log of every level and demo_users = $((seed + 1))"
