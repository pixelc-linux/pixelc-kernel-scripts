#!/bin/sh

KERN_BDIR="./build"
KERN_DTB="nvidia/tegra210-smaug.dtb"
OUTDIR="./output"

if [ -n "$1" ]; then
    KERN_BDIR="$1"
fi

if [ -n "$2" ]; then
    OUTDIR="$2"
fi

if [ ! -x "$(command -v mkimage)" ]; then
    echo "mkimage not found (install u-boot-tools), exitting..."
    exit 1
fi

if [ ! -d "$KERN_BDIR" ]; then
    echo "Kernel build directory not found, exitting..."
    exit 1
fi

echo "Cleaning up..."
rm -rf "$OUTDIR"

echo "Creating output directory ${OUTDIR}..."
mkdir -p "$OUTDIR"

echo "Copying config..."
cp conf/* "$OUTDIR"

echo "Copying raw image..."
cp "${KERN_BDIR}/arch/arm64/boot/Image" "$OUTDIR"
if [ $? -ne 0 ]; then
    echo "Image copy failed (not found?), exitting..."
    rm -rf "$OUTDIR"
    exit 1
fi

echo "Copying device tree blob..."
cp "${KERN_BDIR}/arch/arm64/boot/dts/${KERN_DTB}" "$OUTDIR"

cd "$OUTDIR"
echo "Compressing image..."
lz4c ./Image Image.lz4
if [ $? -ne 0 ]; then
    echo "Image compression failed, exitting..."
    cd ..
    rm -rf "$OUTDIR"
    exit 1
fi

echo "Creating Image.fit..."
mkimage -f Image.its Image.fit
if [ $? -ne 0 ]; then
    echo "U-boot image creation failed, exitting..."
    cd ..
    rm -rf "$OUTDIR"
    exit 1
fi

echo "Created ${OUTDIR}/Image.fit."