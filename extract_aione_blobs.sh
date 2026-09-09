#!/bin/bash

set -e

DEVICE="cloudminds/aione"

ROOT=$(pwd)

OUT="$ROOT/extracted_aione"

DEVICE_PATH="$ROOT/device/$DEVICE"


echo "================================="
echo " AIOne blob extractor"
echo "================================="


if [ ! -f boot.img ]; then
    echo "ERROR: boot.img missing"
    exit 1
fi


if [ ! -f recovery.img ]; then
    echo "ERROR: recovery.img missing"
    exit 1
fi


mkdir -p "$OUT"

mkdir -p "$DEVICE_PATH/prebuilt"

mkdir -p "$DEVICE_PATH/rootdir"

mkdir -p "$DEVICE_PATH/sepolicy"



echo "[1/8] Install tools"


sudo apt update

sudo apt install -y \
android-sdk-libsparse-utils \
cpio \
gzip \
lz4 \
unzip \
file



echo "[2/8] Install unpackbootimg"


if ! command -v unpackbootimg >/dev/null
then

    git clone https://github.com/osm0sis/mkbootimg.git tools-mkbootimg

    cd tools-mkbootimg

    make

    cd ..

    export PATH=$PATH:$ROOT/tools-mkbootimg

fi



echo "[3/8] Extract boot.img"


mkdir -p "$OUT/boot"

cd "$OUT/boot"


unpackbootimg \
-i "$ROOT/boot.img" \
-o .


cd "$ROOT"



echo "[4/8] Extract recovery.img"


mkdir -p "$OUT/recovery"


cd "$OUT/recovery"


unpackbootimg \
-i "$ROOT/recovery.img" \
-o .


cd "$ROOT"



echo "[5/8] Copy kernel"


KERNEL=$(find "$OUT/recovery" \
-name "*zImage*" \
-o \
-name "*kernel*" | head -1)



if [ -z "$KERNEL" ]
then

    KERNEL=$(find "$OUT/boot" \
    -name "*zImage*" \
    -o \
    -name "*kernel*" | head -1)

fi



if [ -z "$KERNEL" ]
then

    echo "ERROR kernel not found"

    exit 1

fi


cp "$KERNEL" \
"$DEVICE_PATH/prebuilt/kernel"



echo "Kernel copied:"


ls -lh "$DEVICE_PATH/prebuilt/kernel"



echo "[6/8] Extract ramdisk"


extract_ramdisk()
{

IMG=$1

DST=$2


mkdir -p "$DST"


cd "$DST"


if [ -f "$IMG/ramdisk.gz" ]
then

    gzip -dc "$IMG/ramdisk.gz" | cpio -idm

elif [ -f "$IMG/ramdisk" ]
then

    cpio -idm < "$IMG/ramdisk"

else

    echo "No ramdisk found"

fi


cd "$ROOT"

}



extract_ramdisk \
"$OUT/recovery" \
"$OUT/recovery_ram"



echo "[7/8] Copy recovery configs"



# init scripts

cp "$OUT/recovery_ram/init"* \
"$DEVICE_PATH/rootdir/" \
2>/dev/null || true



# uevent

cp "$OUT/recovery_ram/ueventd"* \
"$DEVICE_PATH/rootdir/" \
2>/dev/null || true



# fstab

find "$OUT/recovery_ram" \
-name "fstab*" \
-exec cp {} "$DEVICE_PATH/rootdir/" \;



# sepolicy

if [ -f "$OUT/recovery_ram/sepolicy" ]
then

cp "$OUT/recovery_ram/sepolicy" \
"$DEVICE_PATH/sepolicy/"

fi



echo "[8/8] Generate summary"


cat > "$DEVICE_PATH/BLOB_INFO.txt" <<EOF

Device:
CloudMinds A1-901

Platform:
MSM8996

Source:
Original boot.img
Original recovery.img


Extracted:

kernel:
prebuilt/kernel


ramdisk:
rootdir/


sepolicy:
sepolicy/


EOF



echo
echo "================================="
echo " DONE"
echo "================================="


tree "$DEVICE_PATH"