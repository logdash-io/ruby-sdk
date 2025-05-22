#!/bin/sh
set -e

docker build --no-cache -t logdash-demo -f demo/Dockerfile .

docker run --rm -it \
  -e LOGDASH_API_KEY="${LOGDASH_API_KEY}" \
  logdash-demo
