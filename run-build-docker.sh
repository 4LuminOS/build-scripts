#!/usr/bin/env bash

#make failing strictier
set -euo pipefail

IMAGE_NAME="luminos-builder"

docker build -t "$IMAGE_NAME" .
docker run --rm -v "$(pwd):/out" "$IMAGE_NAME"
