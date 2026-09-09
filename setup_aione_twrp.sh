#!/bin/bash

set -e


echo "Create AIOne TWRP device tree"


mkdir -p device/cloudminds/aione

mkdir -p device/cloudminds/aione/prebuilt

mkdir -p device/cloudminds/aione/rootdir

mkdir -p .github/workflows


cat > device/cloudminds/aione/AndroidProducts.mk <<EOF
PRODUCT_MAKEFILES := \\
    \$(LOCAL_DIR)/twrp_aione.mk

COMMON_LUNCH_CHOICES := \\
    twrp_aione-eng
EOF


cat > device/cloudminds/aione/twrp_aione.mk <<EOF
LOCAL_PATH := device/cloudminds/aione


PRODUCT_DEVICE := aione
PRODUCT_NAME := twrp_aione

PRODUCT_BRAND := CloudMinds
PRODUCT_MODEL := A1-901
PRODUCT_MANUFACTURER := CloudMinds


\$(call inherit-product,vendor/twrp/config/common.mk)
EOF



cat > device/cloudminds/aione/Android.mk <<EOF
LOCAL_PATH := \$(call my-dir)

include \$(call all-subdir-makefiles,\$(LOCAL_PATH))
EOF



cat > device/cloudminds/aione/device.mk <<EOF
LOCAL_PATH := device/cloudminds/aione


PRODUCT_COPY_FILES += \\
\$(LOCAL_PATH)/recovery.fstab:recovery/root/etc/recovery.fstab
EOF



cat > device/cloudminds/aione/BoardConfig.mk <<EOF
DEVICE_PATH := device/cloudminds/aione


TARGET_BOARD_PLATFORM := msm8996


TARGET_ARCH := arm64
TARGET_CPU_VARIANT := kryo


BOARD_KERNEL_PAGESIZE := 4096


BOARD_RECOVERYIMAGE_PARTITION_SIZE := 67108864


TARGET_RECOVERY_FSTAB := \\
\$(DEVICE_PATH)/recovery.fstab


TARGET_PREBUILT_KERNEL := \\
\$(DEVICE_PATH)/prebuilt/kernel


TW_THEME := portrait_hdpi


TW_INCLUDE_CRYPTO := true

TW_INCLUDE_FBE := false


SELINUX_IGNORE_NEVERALLOWS := true
EOF



cat > device/cloudminds/aione/recovery.fstab <<EOF
/system ext4 /dev/block/bootdevice/by-name/system

/data ext4 /dev/block/bootdevice/by-name/userdata

/cache ext4 /dev/block/bootdevice/by-name/cache

/boot emmc /dev/block/bootdevice/by-name/boot

/recovery emmc /dev/block/bootdevice/by-name/recovery
EOF



cat > .github/workflows/build.yml <<EOF
name: Build TWRP AIOne


on:
 workflow_dispatch:


jobs:

 build:

  runs-on: ubuntu-22.04


  steps:

  - uses: actions/checkout@v4


  - name: Install
    run: |
      sudo apt update
      sudo apt install -y repo git


  - name: Sync
    run: |

      mkdir twrp

      cd twrp

      repo init \
      -u https://github.com/minimal-manifest-twrp/platform_manifest_twrp_aosp.git \
      -b twrp-8.1


      repo sync -j8


  - name: Copy device

    run: |

      cp -r device twrp/


  - name: Build

    run: |

      cd twrp

      source build/envsetup.sh

      lunch twrp_aione-eng

      mka recoveryimage


  - name: Upload

    uses: actions/upload-artifact@v4

    with:

      name: recovery

      path:

       twrp/out/target/product/aione/recovery.img
EOF


echo "Done"