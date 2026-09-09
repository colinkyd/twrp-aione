#!/bin/bash

set -e


DEVICE="cloudminds/aione"

ROOT=$(pwd)

OUT="$ROOT/extracted_aione"

DEVICE_PATH="$ROOT/device/$DEVICE"


echo "========================================="
echo " CloudMinds A1-901 TWRP Blob Extractor v2"
echo " MSM8996 / Android 7.1"
echo "========================================="


############################################
# Check files
############################################

if [ ! -f boot.img ]; then
    echo "[ERROR] boot.img missing"
    exit 1
fi


if [ ! -f recovery.img ]; then
    echo "[ERROR] recovery.img missing"
    exit 1
fi



############################################
# Install tools
############################################

echo "[1] Installing dependencies"


sudo apt update

sudo apt install -y \
wget \
cpio \
gzip \
lz4 \
file \
tree \
python3



############################################
# Download magiskboot
############################################


if [ ! -f magiskboot ]; then

echo "[2] Download magiskboot"


wget -O magisk.zip \
https://github.com/topjohnwu/Magisk/releases/latest/download/Magisk.zip


unzip -j magisk.zip \
"lib/*/libmagiskboot.so" \
-d .


mv libmagiskboot.so magiskboot


chmod +x magiskboot


fi



############################################
# Prepare folders
############################################


mkdir -p "$OUT"

mkdir -p "$DEVICE_PATH/prebuilt"

mkdir -p "$DEVICE_PATH/rootdir"

mkdir -p "$DEVICE_PATH/sepolicy"



############################################
# Function
############################################


unpack_image()
{

IMG=$1

NAME=$2


echo ""
echo "============================="
echo "Unpack $NAME"
echo "============================="


mkdir -p "$OUT/$NAME"


cp "$IMG" "$OUT/$NAME/"


cd "$OUT/$NAME"


"$ROOT/magiskboot" unpack "$IMG"



cd "$ROOT"


}



############################################
# Unpack boot/recovery
############################################


unpack_image boot.img boot


unpack_image recovery.img recovery



############################################
# Find kernel
############################################


echo "[3] Searching kernel"


KERNEL=$(find "$OUT" \
-name kernel \
-o \
-name kernel.bin \
| head -1)



if [ -z "$KERNEL" ]; then

echo "[ERROR] kernel not found"

exit 1

fi



cp "$KERNEL" \
"$DEVICE_PATH/prebuilt/kernel"



echo "Kernel:"

file "$DEVICE_PATH/prebuilt/kernel"



############################################
# Extract ramdisk
############################################


extract_ramdisk()
{

SRC=$1

DST=$2


mkdir -p "$DST"


if [ -f "$SRC/ramdisk.cpio" ]; then


echo "Extract ramdisk.cpio"


cd "$DST"

cp "$SRC/ramdisk.cpio" .



cpio -idm < ramdisk.cpio


cd "$ROOT"


fi


}



extract_ramdisk \
"$OUT/recovery" \
"$DEVICE_PATH/rootdir"



############################################
# Extract sepolicy
############################################


echo "[4] Extract sepolicy"


SEPOLICY=$(find \
"$DEVICE_PATH/rootdir" \
-name sepolicy \
| head -1)



if [ -n "$SEPOLICY" ]; then


cp "$SEPOLICY" \
"$DEVICE_PATH/sepolicy/"


fi



############################################
# Extract fstab
############################################


echo "[5] Extract fstab"


find "$DEVICE_PATH/rootdir" \
-name "fstab*" \
-o \
-name "*fstab*" \
| while read f
do

cp "$f" "$DEVICE_PATH/"

done



############################################
# Generate info
############################################


cat > "$DEVICE_PATH/BLOB_INFO.txt" <<EOF

Device:
CloudMinds A1-901

SOC:
Qualcomm MSM8996


Android:
7.1.2


Extract source:

boot.img
recovery.img


Generated:

prebuilt/kernel

rootdir/

sepolicy/


EOF



############################################
# Summary
############################################


echo ""
echo "========================================="
echo "Extraction finished"
echo "========================================="


tree "$DEVICE_PATH"