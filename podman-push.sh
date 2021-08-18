#!/bin/bash

set -e
set -u
set -x

DISTRO=$1
ARCHITECTURE=$2

# Retrieve variables from former podman-build.sh
# shellcheck source=/dev/null
. ./"$DISTRO"-"$ARCHITECTURE".conf

if [ -n "${CI_JOB_TOKEN:-}" ]; then
    # Pull image
    podman pull "$CI_REGISTRY_IMAGE/$IMAGE:$TAG"
fi

if [ -n "${CI_JOB_TOKEN:-}" ]; then
    # Update manifests for GitLab. Images must have been pushed beforehand.
    podman manifest create \
        "$CI_REGISTRY_IMAGE/$IMAGE:$VERSION" \
        "$CI_REGISTRY_IMAGE/$IMAGE:$TAG"
    podman manifest create \
        "$CI_REGISTRY_IMAGE/$IMAGE":latest \
        "$CI_REGISTRY_IMAGE/$IMAGE:$TAG"
fi

if [ -n "${DOCKER_HUB_ACCESS_TOKEN:-}" ]; then
    # Push to Docher Hub registry
    podman tag "$CI_REGISTRY_IMAGE/$IMAGE:$TAG" docker.io/"$DOCKER_HUB_ORGANIZATION/$IMAGE:$ARCHITECTURE"
    podman push docker.io/"$DOCKER_HUB_ORGANIZATION/$IMAGE:$ARCHITECTURE"

    # XXX: We don't push the versioned image because we are not
    # able to cleanup old images and "docker pull" will fetch all
    # versions of a given image...
    # Don't push
    #docker tag $CI_REGISTRY_IMAGE/$IMAGE:$TAG $DOCKER_HUB_REGISTRY_IMAGE/$IMAGE:$TAG
    #docker push $DOCKER_HUB_ORGANIZATION/$IMAGE:$TAG

    # This operation is currently failing with "The operation is unsupported.".
    #./docker-cleanup.sh $DOCKER_HUB_ORGANIZATION/$IMAGE

    # Update manifest for Docker Hub. Images must have been pushed beforehand.
    podman manifest create \
        docker.io/"$DOCKER_HUB_ORGANIZATION/$IMAGE":latest \
        docker.io/"$DOCKER_HUB_ORGANIZATION/$IMAGE:$ARCHITECTURE"
fi
