#!/bin/bash

# Configuration
HUGO_IMAGE="codeberg.org/b4mad/hugo:v1.147.2"
SRC_DIR="/src" # Internal container source directory
PORT_MAPPING="1313:1313" # Host_Port:Container_Port

# Ensure podman is available
if ! command -v podman &> /dev/null
then
    echo "podman could not be found. Please install podman to use this script."
    exit 1
fi

# Pull the Hugo container image if it's not already present
echo "Checking for Hugo image: $HUGO_IMAGE"
if ! podman image inspect "$HUGO_IMAGE" &> /dev/null; then
    echo "Image '$HUGO_IMAGE' not found locally. Pulling..."
    podman pull "$HUGO_IMAGE"
    if [ $? -ne 0 ]; then
        echo "Failed to pull image '$HUGO_IMAGE'. Exiting."
        exit 1
    fi
    echo "Image '$HUGO_IMAGE' pulled successfully."
else
    echo "Image '$HUGO_IMAGE' found locally."
fi

echo "Starting Hugo server in container on port ${PORT_MAPPING%%:*} (http://localhost:${PORT_MAPPING%%:*})"
echo "Watching for changes in $(pwd)"

# Run Hugo server in the container with port mapping and watch for changes
podman run --rm -it \
           -p "$PORT_MAPPING" \
           -v "$(pwd):$SRC_DIR" \
           -w "$SRC_DIR" \
           "$HUGO_IMAGE" \
           hugo server --bind 0.0.0.0 --port ${PORT_MAPPING##*:} --source "$SRC_DIR" --watch --liveReload --disableFastRender

if [ $? -eq 0 ]; then
    echo "Hugo server stopped."
else
    echo "Hugo server encountered an error."
    exit 1
fi
