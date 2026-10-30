#
# Copyright (C) 2026 BALMUDA Phone A101BM port
#
# SPDX-License-Identifier: Apache-2.0
#

$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/full_base_telephony.mk)

$(call inherit-product, device/balmuda/A101BM/device.mk)

$(call inherit-product, vendor/lineage/config/common_full_phone.mk)

PRODUCT_NAME := lineage_A101BM
PRODUCT_DEVICE := A101BM
PRODUCT_BRAND := BALMUDA
PRODUCT_MODEL := A101BM
PRODUCT_MANUFACTURER := BALMUDA

PRODUCT_GMS_CLIENTID_BASE := android-balmuda

PRODUCT_BUILD_PROP_OVERRIDES += \
    BuildDesc="A101BM-user 12 SKQ1.220303.001 1.280PO.0686.a release-keys" \
    DeviceProduct=A101BM

BUILD_FINGERPRINT := BALMUDA/A101BM/A101BM:12/SKQ1.220303.001/1.280PO.0686.a:user/release-keys
