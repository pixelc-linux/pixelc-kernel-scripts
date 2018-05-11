#!/bin/sh

if [ -z "$MKBOOTIMG" ]; then
    MKBOOTIMG="mkbootimg"
fi

if [ ! -x "$(command -v $MKBOOTIMG)" ]; then
    echo "mkbootimg not found (install android-tools-mkbootimg), exitting..."
    exit 1
fi

if [ -z "$1" ] || [ -z "$2" ]; then
    echo "Usage: $0 Image.fit initramfs.cpio.lz4"
    exit 1
fi

IMAGEFIT="$1"
RAMDISK="$2"

OUTPUT="boot.img.unsigned"
if [ -n "$3" ]; then
    OUTPUT="$3"
fi

rm -f "$OUTPUT"
"$MKBOOTIMG" --kernel "$1"  --ramdisk "$2" -o "$OUTPUT"
if [ $? -ne 0 ]; then
    echo "mkbootimg failed, exitting..."
fi

echo "Created ${OUTPUT}."
