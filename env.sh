#!/bin/sh

if [ -z "$KERN_DEFCONFIG" ]; then
    KERN_DEFCONFIG="smaug_defconfig"
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
    echo "If you want to override the sed implementation used by the build,"
    echo "set the SED environment variable. By default it will use sed on"
    echo "GNU systems and gsed on non-GNU systems."
    echo "Also, if you want to override the make implementation, equivalently"
    echo "set the MAKE environment variable. By default it will use make if"
    echo "GNU and gmake if not."
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
    KERN_BDIR="$PWD/$KERN_BUILDDIR"
fi

TMP_PREFIX="$(mktemp -d gbin-XXXXXXXX)"
TMP_PREFIX_ABS="${PWD}/${TMP_PREFIX}"

export PATH="${TMP_PREFIX_ABS}:${PATH}"

# need to deal with sed
if [ -n "$SED" ] && [ "$SED" != "sed" ]; then
    # user overridden sed
    SED="$SED"
elif [ -z "$(sed --version 2>&1 | head -n1 | grep '(GNU sed)')" ]; then
    # non-GNU default sed, try gsed
    SED=gsed
else
    # GNU default sed
    SED=sed
fi

# same with make
if [ -n "$MAKE" ] && [ "$MAKE" != "make" ]; then
    # user overridden make
    MAKE="$MAKE"
elif [ -z "$(make --version 2>&1 | head -n1 | grep 'GNU Make')" ]; then
    MAKE=gmake
else
    MAKE=make
fi

if [ ! -x "$(command -v $SED)" ]; then
    echo "'$SED' not found, exitting..."
    help
    exit 1
fi

if [ ! -x "$(command -v $MAKE)" ]; then
    echo "'$MAKE' not found, exitting..."
    help
    exit 1
fi

if [ "$SED" != "sed" ]; then
    ln -s "$(which $SED)" "${TMP_PREFIX}/sed"
fi

if [ "$MAKE" != "make" ]; then
    ln -s "$(which $MAKE)" "${TMP_PREFIX}/make"
fi
