#!/bin/bash

# Default baseURL, can be overridden by an environment variable
BASE_URL=${HUGO_BASE_URL:-""}

if [ -z "$BASE_URL" ]; then
  echo "Warning: HUGO_BASE_URL is not set. Building with relative URLs."
  podman run --rm -v "$(pwd):/src" codeberg.org/b4mad/hugo:v1.147.2 hugo --minify
else
  echo "Building with baseURL: $BASE_URL"
  podman run --rm -v "$(pwd):/src" codeberg.org/b4mad/hugo:v1.147.2 hugo --minify --baseURL "$BASE_URL"
fi