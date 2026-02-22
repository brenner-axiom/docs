#!/bin/bash

podman run --rm -v "$(pwd):/src" -p 1313:1313 codeberg.org/b4mad/hugo:v1.147.2 hugo server --bind 0.0.0.0