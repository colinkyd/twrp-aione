LOCAL_PATH := device/cloudminds/aione


PRODUCT_DEVICE := aione
PRODUCT_NAME := twrp_aione

PRODUCT_BRAND := CloudMinds
PRODUCT_MODEL := A1-901
PRODUCT_MANUFACTURER := CloudMinds


$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit.mk)

$(call inherit-product, vendor/twrp/config/common.mk)


PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/rootdir/init.rc:root/init.rc \
    $(LOCAL_PATH)/rootdir/init.qcom.sh:root/init.qcom.sh \
    $(LOCAL_PATH)/rootdir/init.qcom.usb.sh:root/init.qcom.usb.sh \
    $(LOCAL_PATH)/rootdir/fstab.qcom:root/fstab.qcom \
    $(LOCAL_PATH)/rootdir/ueventd.rc:root/ueventd.rc \
    $(LOCAL_PATH)/rootdir/ueventd.qcom.rc:root/ueventd.qcom.rc