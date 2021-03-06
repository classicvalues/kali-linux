#!/bin/bash

set -e
set -u

DISTROS="${1:-kali-rolling}"
EXTRA_DISTROS="${2:-}"
ARCHS="${3:-amd64}"

[ "$DISTROS" == all ] && DISTROS="kali-rolling kali-dev kali-last-snapshot"
[ "$EXTRA_DISTROS" == all ] && EXTRA_DISTROS="kali-experimental kali-bleeding-edge"
[ "$ARCHS" == all ] && ARCHS="amd64 arm64 armhf"

echo "Distributions: $DISTROS"
echo "Extra distros: $EXTRA_DISTROS"
echo "Architectures: $ARCHS"

RUN=$(test $(id -u) -eq 0 || echo sudo)

for distro in $DISTROS; do
    for arch in $ARCHS; do
        echo "========================================"
        echo "Building image $distro/$arch"
        echo "========================================"
        $RUN ./build-rootfs.sh "$distro" "$arch"
        $RUN ./docker-build.sh "$distro" "$arch"
        $RUN ./docker-test.sh  "$distro" "$arch"
        $RUN ./docker-push.sh  "$distro" "$arch"
    done
    $RUN ./docker-push-manifest.sh "$distro" "$ARCHS"
done

for distro in $EXTRA_DISTROS; do
    for arch in $ARCHS; do
        echo "========================================"
        echo "Building image $distro/$arch"
        echo "========================================"
        $RUN ./docker-build-extra.sh "$distro" "$arch"
        $RUN ./docker-test.sh "$distro" "$arch"
        $RUN ./docker-push.sh "$distro" "$arch"
    done
    $RUN ./docker-push-manifest.sh "$distro" "$ARCHS"
done
