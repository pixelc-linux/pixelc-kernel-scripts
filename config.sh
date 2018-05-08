#!/bin/sh

# cross-compiler and configuration
source ./env.sh

cd "$KERNPATH"

CONFIGTOOL="menuconfig"
if [ -n "$KERN_CONFIGTOOL" ]; then
    CONFIGTOOL="$KERN_CONFIGTOOL"
fi

make ARCH=arm64 CROSS_COMPILE="$KERN_CROSS" \
    KBUILD_DEFCONFIG="$KERN_DEFCONFIG" "$CONFIGTOOL" O="$KERN_BDIR" "$@"
