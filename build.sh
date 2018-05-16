#!/bin/sh

# cross-compiler and configuration
export KERN_NOCONFIG=1
. ./env.sh

cd "$KERNPATH"

make ARCH=arm64 CROSS_COMPILE="$KERN_CROSS" \
    KBUILD_DEFCONFIG="$KERN_DEFCONFIG" O="$KERN_BDIR" "$@"

rm -rf "$TMP_PREFIX_ABS"
