#!/bin/sh

if [ -z "$FUTILITY" ]; then
    FUTILITY="futility"
fi
if [ ! -x "$(command -v $FUTILITY)" ]; then
    echo "futility not found (install vboot-kernel-utils), exitting..."
    exit 1
fi

VBOOT_KEY_URL="https://chromium.googlesource.com/chromiumos/platform/vboot_reference/+/master/tests/devkeys"

VBOOT_PUBKEY="kernel_data_key.vbpubk"
VBOOT_PRIVKEY="kernel_data_key.vbprivk"
VBOOT_PUBKEY_URL="${VBOOT_KEY_URL}/${VBOOT_PUBKEY}?format=TEXT"
VBOOT_PRIVKEY_URL="${VBOOT_KEY_URL}/${VBOOT_PRIVKEY}?format=TEXT"
VBOOT_KEY_DIR="./signing_keys"

VBOOT_PUBKEYF="${VBOOT_KEY_DIR}/${VBOOT_PUBKEY}"
VBOOT_PRIVKEYF="${VBOOT_KEY_DIR}/${VBOOT_PRIVKEY}"

mkdir -p "$VBOOT_KEY_DIR"

if [ ! -f "$VBOOT_PUBKEYF" ] || [ ! -f "$VBOOT_PRIVKEYF" ]; then
    rm -f "$VBOOT_PUBKEYF"
    rm -f "$VBOOT_PRIVKEYF"
    if [ ! -x "$(command -v wget)" ]; then
        echo "Wget is not installed, exitting..."
        exit 1
    fi
    # should be on most systems
    if [ ! -x "$(command -v perl)" ]; then
        echo "Perl is not installed, exitting..."
        exit 1
    fi
    echo "Signing keys not found, downloading..."
    wget "$VBOOT_PUBKEY_URL" -O "$VBOOT_PUBKEYF.base64"
    if [ $? -eq 0 ]; then
        wget "$VBOOT_PRIVKEY_URL" -O "$VBOOT_PRIVKEYF.base64"
    fi
    if [ $? -ne 0 ]; then
        echo "Wget failed, exitting..."
        exit 1
    fi
    cat "$VBOOT_PUBKEYF.base64" | \
        perl -MMIME::Base64 -ne 'printf "%s\n",decode_base64($_)' > \
            "$VBOOT_PUBKEYF"
    cat "$VBOOT_PRIVKEYF.base64" | \
        perl -MMIME::Base64 -ne 'printf "%s\n",decode_base64($_)' > \
            "$VBOOT_PRIVKEYF"
    rm -f "$VBOOT_PUBKEYF.base64"
    rm -f "$VBOOT_PRIVKEYF.base64"
fi

if [ ! -f "$VBOOT_PUBKEYF" ] || [ ! -f "$VBOOT_PRIVKEYF" ]; then
    echo "Signing keys not found, exitting..."
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
    --datapubkey "$VBOOT_PUBKEYF" --signprivate "$VBOOT_PRIVKEYF"
if [ $? -ne 0 ]; then
    echo "Error writing keyblock, exitting..."
    rm -f "$EMPTY"
    exit 1
fi

"$FUTILITY" vbutil_kernel --pack "$OUTPUT" \
    --keyblock "$KEYBLOCK" --signprivate "$VBOOT_PRIVKEYF" --version 1 \
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
