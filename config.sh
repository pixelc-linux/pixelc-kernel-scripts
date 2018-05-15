#!/bin/sh

# cross-compiler and configuration
. ./env.sh

cd "$KERNPATH"

CONFIGTOOL="menuconfig"
if [ -n "$KERN_CONFIGTOOL" ]; then
    CONFIGTOOL="$KERN_CONFIGTOOL"
fi

if [ "$KERN_CONFIGTOOL" = "defconfig" ] && [ -z "$KERN_BUILD_IN_TREE" ]; then
    rm -rf "$KERN_BUILDDIR"
    mkdir -p "$KERN_BUILDDIR"
fi

make ARCH=arm64 CROSS_COMPILE="$KERN_CROSS" \
    KBUILD_DEFCONFIG="$KERN_DEFCONFIG" "$CONFIGTOOL" O="$KERN_BDIR" "$@"

rm -rf "$TMP_PREFIX_ABS"
