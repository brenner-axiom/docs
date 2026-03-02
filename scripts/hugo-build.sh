#!/bin/bash

# Configuration
HUGO_IMAGE="codeberg.org/b4mad/hugo:v1.147.2"
OUTPUT_DIR="./public"
SRC_DIR="/src" # Internal container source directory

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

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

echo "Building Hugo site using container image $HUGO_IMAGE..."

# Run Hugo build in the container
# Mount current directory as /src inside the container
# Output public directory from container to host's ./public
podman run --rm \
           -v "$(pwd):$SRC_DIR" \
           -w "$SRC_DIR" \
           "$HUGO_IMAGE" \
           hugo --gc --minify -d "$OUTPUT_DIR"

if [ $? -eq 0 ]; then
    echo "Hugo site built successfully to '$OUTPUT_DIR'."
else
    echo "Hugo build failed."
    exit 1
fi
