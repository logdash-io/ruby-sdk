#!/bin/sh
set -e

cd "$(dirname "$0")/.."
echo "Building LogDash demo Docker image (using published gem)..."
docker build --no-cache -t logdash-demo -f demo/Dockerfile .

echo
echo "Running LogDash demo..."
echo
docker run --rm -it \
  -e LOGDASH_API_KEY="${LOGDASH_API_KEY:-YOUR_API_KEY_HERE}" \
  logdash-demo

echo
echo "Demo completed!" 