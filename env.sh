#!/bin/sh

if [ -z "$KERN_DEFCONFIG" ]; then
    KERN_DEFCONFIG="tegra21_defconfig"
fi

KERN_CROSS="aarch64-linux-gnu-"

if [ -z "$KERN_BUILDDIR" ]; then
    KERN_BUILDDIR="./build"
fi

help() {
    if [ -n "$KERN_NOCONFIG" ]; then
        echo "Usage: $0 kpath [make params]"
        echo ""
    else
        echo "Usage: $0 kpath kdefconfig [make params]"
        echo ""
        echo "The configuration defaults to $KERN_DEFCONFIG."
    fi
    echo "By default the kernel is built out-of-tree in $KERN_BUILDDIR."
    echo "You can override that with the KERN_BUILDDIR variable, or you can"
    echo "make it build in-tree by setting KERN_BUILD_IN_TREE."
    echo "You can also specify KERNEL_CROSS_PREFIX for a custom cross gcc"
    echo "This defaults to $KERN_CROSS. If you want to use the default"
    echo "host compiler, specify KERN_NO_CROSS."
}

if [ -z "$1" ]; then
    echo "No kernel path specified..."
    help
    exit 1
fi

KERNPATH="$1"
shift

if [ -z "$KERN_NOCONFIG" ]; then
    if [ -n "$1" ]; then
        KERN_DEFCONFIG="$1"
        shift
    fi
fi
if [ -n "$KERN_CROSS_PREFIX" ]; then
    KERN_CROSS="$KERN_CROSS_PREFIX"
fi
if [ -n "$KERN_NO_CROSS" ]; then
    KERN_CROSS=""
fi

if [ ! -x "$(command -v ${KERN_CROSS}gcc)" ]; then
    echo "Cross-compiler not found, exitting..."
    help
    exit 1
fi

if [ -n "$KERN_BUILD_IN_TREE" ]; then
    KERN_BDIR="$1"
else
    rm -rf "$KERN_BUILDDIR"
    mkdir -p "$KERN_BUILDDIR"
    KERN_BDIR="$PWD/$KERN_BUILDDIR"
fi
