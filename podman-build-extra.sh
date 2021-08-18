#!/bin/bash

set -e
set -u

DISTRO=$1
ARCHITECTURE=$2

CI_REGISTRY_IMAGE=${CI_REGISTRY_IMAGE:-"kalilinux"}

# Build the same version as for kali-rolling
# shellcheck source=/dev/null
VERSION=$(. ./kali-rolling-"$ARCHITECTURE".conf; echo "$VERSION")
IMAGE=$DISTRO

TAG=$VERSION-$ARCHITECTURE

podman build \
    --build-arg CI_REGISTRY_IMAGE="$CI_REGISTRY_IMAGE"\
    --build-arg TAG="$TAG" \
    --file extra/"$IMAGE" \
    --arch "$ARCHITECTURE" \
    --tag "$CI_REGISTRY_IMAGE/$IMAGE:$TAG" \
    .

if [ -n "${CI_JOB_TOKEN:-}" ]; then
    # Push the image so that subsequent jobs can fetch it
    podman push "$CI_REGISTRY_IMAGE/$IMAGE:$TAG"
fi

cat >"$DISTRO-$ARCHITECTURE".conf <<END
CI_REGISTRY_IMAGE="$CI_REGISTRY_IMAGE"
IMAGE="$IMAGE"
TAG="$TAG"
VERSION="$VERSION"
END
