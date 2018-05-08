#!/bin/sh

if [ -z "$FUTILITY" ]; then
    FUTILITY="futility"
fi
if [ ! -x "$(command -v $FUTILITY)" ]; then
    echo "futility not found (install vboot-kernel-utils), exitting..."
    exit 1
fi

if [ -z "$VBOOT_PATH" ]; then
    VBOOT_PATH="/usr/share/vboot"
fi
VBOOT_PUBK="${VBOOT_PATH}/devkeys/kernel_data_key.vbpubk"
VBOOT_PRIVK="${VBOOT_PATH}/devkeys/kernel_data_key.vbprivk"

if [ ! -f "$VBOOT_PUBK" ] || [ ! -f "$VBOOT_PRIVK" ]; then
    echo "Signing keys not found (install vboot-kernel-utils), exitting..."
    exit 1
fi

IMG_UNSIGNED="./boot.img.unsigned"
if [ -n "$1" ]; then
    IMG_UNSIGNED="$1"
fi

if [ ! -f "$IMG_UNSIGNED" ]; then
    echo "Image not found, exitting..."
    exit 1
fi

OUTPUT="./boot.img"
if [ -n "$2" ]; then
    OUTPUT="$2"
fi

EMPTY="$(mktemp ./tmp.XXXXXXXX)"
echo " " > "$EMPTY"

KEYBLOCK="${OUTPUT}.keyblock"

echo "Cleaning up old files..."
rm -f "$KEYBLOCK" "$OUTPUT"
if [ $? -ne 0 ]; then
    echo "Cleanup failed, exitting..."
    rm -f "$EMPTY"
    exit 1
fi

echo "Signing..."

"$FUTILITY" vbutil_keyblock --pack "$KEYBLOCK" \
    --datapubkey "$VBOOT_PUBK" --signprivate "$VBOOT_PRIVK"
if [ $? -ne 0 ]; then
    echo "Error writing keyblock, exitting..."
    rm -f "$EMPTY"
    exit 1
fi

"$FUTILITY" vbutil_kernel --pack "$OUTPUT" \
    --keyblock "$KEYBLOCK" --signprivate "$VBOOT_PRIVK" --version 1 \
    --vmlinuz "$IMG_UNSIGNED" --config "$EMPTY" --arch arm \
    --bootloader "$EMPTY" --flags 0x1
if [ $? -ne 0 ]; then
    echo "Signing failed, exitting..."
    rm -f "$KEYBLOCK"
    rm -f "$EMPTY"
    exit 1
fi

echo "Cleaning up temporary files..."
rm -f "$EMPTY"
rm -f "$KEYBLOCK"

echo "Created ${OUTPUT}."
