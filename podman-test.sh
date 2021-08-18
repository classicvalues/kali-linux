#!/bin/bash

set -e
set -u

DISTRO=$1
ARCHITECTURE=$2

# Retrieve variables from former podman-build.sh
# shellcheck source=/dev/null
. ./"$DISTRO"-"$ARCHITECTURE".conf

case "$ARCHITECTURE" in
    amd64) machine="x86_64"  ;;
    arm64) machine="aarch64" ;;
    armhf) machine="armv7l"  ;;
esac

if [ -n "${CI_JOB_TOKEN:-}" ]; then
    podman pull "$CI_REGISTRY_IMAGE/$IMAGE:$TAG"
fi

TEST_ARCH=$(podman run --rm "$CI_REGISTRY_IMAGE/$IMAGE:$TAG" uname -m)
if [ "$machine" == "$TEST_ARCH" ]; then
    echo "OK: Got expected architecture '$TEST_ARCH'"
else
    echo >&2 "ERROR: Incorrect architecture '$TEST_ARCH' (expected '$machine')"
    exit 1
fi
