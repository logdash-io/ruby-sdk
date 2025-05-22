#!/bin/sh
set -e

echo "Building LogDash demo Docker image (using published gem)..."
docker build --no-cache -t logdash-demo -f demo/Dockerfile .

echo
echo "Running LogDash demo..."
echo

# Run in non-interactive mode which works everywhere
docker run --rm \
  -e LOGDASH_API_KEY="${LOGDASH_API_KEY:-YOUR_API_KEY_HERE}" \
  logdash-demo

echo
echo "Demo completed!"
