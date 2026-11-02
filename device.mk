#
# Copyright (C) 2022-2024 The LineageOS Project
# Copyright (C) 2026 BALMUDA Phone A101BM port
#
# SPDX-License-Identifier: Apache-2.0
#
# Based on LineageOS device/motorola/sm7250-common/common.mk (lineage-24.0).
#

$(call inherit-product, hardware/qcom-caf/common/common.mk)
$(call inherit-product, frameworks/native/build/phone-xhdpi-6144-dalvik-heap.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/virtual_ab_ota.mk)

# API levels
BOARD_SHIPPING_API_LEVEL := 30
PRODUCT_SHIPPING_API_LEVEL := 30

# A/B
AB_OTA_PARTITIONS += \
    boot \
    dtbo \
    odm \
    product \
    recovery \
    system \
    system_ext \
    vbmeta \
    vbmeta_system \
    vendor

PRODUCT_PACKAGES += \
    update_engine \
    update_engine_sideload \
    update_verifier

PRODUCT_PACKAGES_DEBUG += \
    update_engine_client

AB_OTA_POSTINSTALL_CONFIG += \
    RUN_POSTINSTALL_system=true \
    POSTINSTALL_PATH_system=system/bin/otapreopt_script \
    FILESYSTEM_TYPE_system=ext4 \
    POSTINSTALL_OPTIONAL_system=true

AB_OTA_POSTINSTALL_CONFIG += \
    RUN_POSTINSTALL_vendor=true \
    POSTINSTALL_PATH_vendor=bin/checkpoint_gc \
    FILESYSTEM_TYPE_vendor=ext4 \
    POSTINSTALL_OPTIONAL_vendor=true

PRODUCT_PACKAGES += \
    checkpoint_gc \
    otapreopt_script

# Audio
PRODUCT_PACKAGES += \
    audio.bluetooth.default \
    audio.primary.lito \
    audio.r_submix.default \
    audio.usb.default \
    android.hardware.audio@6.0-impl \
    android.hardware.audio.effect@6.0-impl \
    android.hardware.audio.service \
    android.hardware.soundtrigger@2.3-impl \
    android.hardware.bluetooth.audio-impl \
    libaudio-resampler \
    libaudioroute \
    libhdmiedid \
    libhfp \
    libqcomvisualizer \
    libqcomvoiceprocessing \
    libsndmonitor \
    libvolumelistener \
    libtinycompress \
    liba2dpoffload

PRODUCT_COPY_FILES += \
    frameworks/av/services/audiopolicy/config/r_submix_audio_policy_configuration.xml:$(TARGET_COPY_OUT_VENDOR)/etc/r_submix_audio_policy_configuration.xml \
    $(LOCAL_PATH)/configs/audio/audio_policy_configuration.xml:$(TARGET_COPY_OUT_VENDOR)/etc/audio_policy_configuration.xml

# addon.d: keep Play services moved by the TWRP GMS fix across updates
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/addon.d/40-balmuda-gms.sh:$(TARGET_COPY_OUT_SYSTEM)/addon.d/40-balmuda-gms.sh

# Boot control
PRODUCT_PACKAGES += \
    android.hardware.boot-service.qti \
    android.hardware.boot-service.qti.recovery
$(call soong_config_set_bool,QTI_GPT_UTILS,USE_BSG_FRAMEWORK,false)

# Camera (stock HAL)
PRODUCT_PACKAGES += \
    android.hardware.camera.provider@2.4-impl \
    android.hardware.camera.provider@2.4-service_64


# Display
PRODUCT_PACKAGES += \
    android.hardware.graphics.mapper@3.0-impl-qti-display \
    android.hardware.graphics.mapper@4.0-impl-qti-display \
    gralloc.qcom \
    vendor.qti.hardware.display.allocator-service \
    vendor.qti.hardware.display.composer-service \
    vendor.qti.hardware.memtrack-service

# DRM
PRODUCT_PACKAGES += \
    android.hardware.drm-service.clearkey

# Fastbootd
PRODUCT_PACKAGES += \
    fastbootd
$(call soong_config_set_bool,fastbootd,zero_packet,true)

# GPS
PRODUCT_PACKAGES += \
    android.hardware.gnss@2.1-impl-qti \
    android.hardware.gnss@2.1-service-qti \
    libbatching \
    libgeofencing \
    libgnss \
    apdr.conf \
    flp.conf \
    gps.conf \
    izat.conf \
    lowi.conf \
    sap.conf \
    xtwifi.conf

# HALs built from source instead of the stock services of the same name
PRODUCT_PACKAGES += \
    android.hardware.atrace@1.0-service \
    android.hardware.biometrics.fingerprint@2.1-service \
    android.hardware.cas@1.2-service \
    android.hardware.media.omx@1.0-service

# First stage mount fstab
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/init/fstab.default:$(TARGET_COPY_OUT_RAMDISK)/fstab.default

# Stock vendor ueventd rules (only /vendor/etc/ueventd.rc is imported), with /dev/hw_random readable by prng_seeder
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/init/ueventd.vendor.rc:$(TARGET_COPY_OUT_VENDOR)/etc/ueventd.rc

# Init
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/init/init.a101bm.rc:$(TARGET_COPY_OUT_VENDOR)/etc/init/init.a101bm.rc

# Stock rc files: USB without the UDC rebind loop, init.qcom.rc without the HIDL wpa_supplicant service
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/init/init.kc.usb.jp.ss.rc:$(TARGET_COPY_OUT_VENDOR)/etc/init/init.kc.usb.jp.ss.rc \
    $(LOCAL_PATH)/init/init.qcom.rc:$(TARGET_COPY_OUT_VENDOR)/etc/init/hw/init.qcom.rc

# Stock seccomp policies plus syscalls used by the current bionic
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/seccomp/atfwd@2.0.policy:$(TARGET_COPY_OUT_VENDOR)/etc/seccomp_policy/atfwd@2.0.policy \
    $(LOCAL_PATH)/seccomp/wfdhdcphalservice.policy:$(TARGET_COPY_OUT_VENDOR)/etc/seccomp_policy/wfdhdcphalservice.policy

# vndbinder
PRODUCT_PACKAGES += \
    vndservicemanager

# NFC / Secure Element (stock NXP SN100 blobs)
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/init/android.hardware.nfc@1.2-service-a101bm.rc:$(TARGET_COPY_OUT_VENDOR)/etc/init/android.hardware.nfc@1.2-service-a101bm.rc

# Health
PRODUCT_PACKAGES += \
    android.hardware.health-service.qti \
    android.hardware.health-service.qti_recovery


# IPACM
PRODUCT_PACKAGES += \
    ipacm \
    IPACM_cfg.xml

# Kernel (stock prebuilt)
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/prebuilt/kernel:kernel

# The stock 4.19 kernel is older than the FCM kernel requirements
PRODUCT_OTA_ENFORCE_VINTF_KERNEL_REQUIREMENTS := false

# Lineage Health
PRODUCT_PACKAGES += \
    vendor.lineage.health-service.default

# Memory
PRODUCT_ENABLE_UFFD_GC := true

# Overlays
DEVICE_PACKAGE_OVERLAYS += \
    $(LOCAL_PATH)/overlay \
    $(LOCAL_PATH)/overlay-lineage
PRODUCT_ENFORCE_RRO_TARGETS := *

# Partitions
PRODUCT_USE_DYNAMIC_PARTITIONS := true
PRODUCT_PACKAGES += \
    vendor_bt_firmware_mountpoint \
    vendor_dsp_mountpoint \
    vendor_firmware_mnt_mountpoint

# Permissions
PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/android.hardware.audio.low_latency.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.audio.low_latency.xml \
    frameworks/native/data/etc/android.hardware.bluetooth.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.bluetooth.xml \
    frameworks/native/data/etc/android.hardware.bluetooth_le.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.bluetooth_le.xml \
    frameworks/native/data/etc/android.hardware.camera.flash-autofocus.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.camera.flash-autofocus.xml \
    frameworks/native/data/etc/android.hardware.camera.front.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.camera.front.xml \
    frameworks/native/data/etc/android.hardware.camera.full.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.camera.full.xml \
    frameworks/native/data/etc/android.hardware.fingerprint.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.fingerprint.xml \
    frameworks/native/data/etc/android.hardware.location.gps.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.location.gps.xml \
    frameworks/native/data/etc/android.hardware.nfc.hce.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.nfc.hce.xml \
    frameworks/native/data/etc/android.hardware.nfc.hcef.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.nfc.hcef.xml \
    frameworks/native/data/etc/android.hardware.nfc.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.nfc.xml \
    frameworks/native/data/etc/android.hardware.opengles.aep.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.opengles.aep.xml \
    frameworks/native/data/etc/android.hardware.sensor.accelerometer.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.sensor.accelerometer.xml \
    frameworks/native/data/etc/android.hardware.sensor.barometer.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.sensor.barometer.xml \
    frameworks/native/data/etc/android.hardware.sensor.compass.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.sensor.compass.xml \
    frameworks/native/data/etc/android.hardware.sensor.gyroscope.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.sensor.gyroscope.xml \
    frameworks/native/data/etc/android.hardware.sensor.light.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.sensor.light.xml \
    frameworks/native/data/etc/android.hardware.sensor.proximity.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.sensor.proximity.xml \
    frameworks/native/data/etc/android.hardware.sensor.stepcounter.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.sensor.stepcounter.xml \
    frameworks/native/data/etc/android.hardware.sensor.stepdetector.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.sensor.stepdetector.xml \
    frameworks/native/data/etc/android.hardware.telephony.gsm.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.telephony.gsm.xml \
    frameworks/native/data/etc/android.hardware.telephony.ims.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.telephony.ims.xml \
    frameworks/native/data/etc/android.hardware.touchscreen.multitouch.jazzhand.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.touchscreen.multitouch.jazzhand.xml \
    frameworks/native/data/etc/android.hardware.usb.accessory.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.usb.accessory.xml \
    frameworks/native/data/etc/android.hardware.usb.host.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.usb.host.xml \
    frameworks/native/data/etc/android.hardware.vulkan.compute-0.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.vulkan.compute-0.xml \
    frameworks/native/data/etc/android.hardware.vulkan.level-1.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.vulkan.level-1.xml \
    frameworks/native/data/etc/android.hardware.vulkan.version-1_1.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.vulkan.version-1_1.xml \
    frameworks/native/data/etc/android.hardware.wifi.direct.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.wifi.direct.xml \
    frameworks/native/data/etc/android.hardware.wifi.passpoint.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.wifi.passpoint.xml \
    frameworks/native/data/etc/android.hardware.wifi.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.wifi.xml \
    frameworks/native/data/etc/android.software.midi.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.software.midi.xml \
    frameworks/native/data/etc/android.software.sip.voip.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.software.sip.voip.xml

# Power
PRODUCT_PACKAGES += \
    android.hardware.power-service.lineage-libperfmgr \
    libqti-perfd-client

# powerhint from LineageOS motorola/nairo (same SoC)
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/configs/powerhint.json:$(TARGET_COPY_OUT_VENDOR)/etc/powerhint.json

# Camera: by default the Kyocera CamX HAL (maxNonHFRFPS=30) gives sensor modes above 30 fps to HFR only;
# with 60 a regular session gets AE (60,60)/(15,60) and 1080p60.
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/configs/camera/camxoverridesettings.txt:$(TARGET_COPY_OUT_VENDOR)/etc/camera/camxoverridesettings.txt

# Codec2 video codecs: the stock media_codecs_c2.xml lists hardware codecs as OMX.qcom.* only, Android 17 uses
# Codec2, so without c2.qti.* video recording fell back to the software c2.android.*. Excluded from the blobs.
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/media/media_codecs_c2.xml:$(TARGET_COPY_OUT_VENDOR)/etc/media_codecs_c2.xml \
    $(LOCAL_PATH)/media/media_codecs_performance_c2.xml:$(TARGET_COPY_OUT_VENDOR)/etc/media_codecs_performance_c2.xml

# c2.qti: linear (not UBWC) encoder input. The ArcSoft camera node (EIS, low-light denoise) rejects UBWC
# frames, so video from apps with a still stream (Open Camera, GCam) came out green or as noise.
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/media/video_system_specs.json:$(TARGET_COPY_OUT_VENDOR)/etc/video_system_specs.json

# Recording profiles: stock media_profiles_vendor.xml + 2160p30 for camera 0 (apps read it, CameraX
# offers no 4K without the profile). Excluded from the blobs.
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/media/media_profiles_vendor.xml:$(TARGET_COPY_OUT_VENDOR)/etc/media_profiles_vendor.xml

# Sensors
PRODUCT_PACKAGES += \
    android.hardware.sensors-service.multihal

# Soong namespaces
PRODUCT_SOONG_NAMESPACES += \
    $(LOCAL_PATH) \
    hardware/google/interfaces \
    hardware/google/pixel \
    hardware/google/pixel/power-libperfmgr \
    hardware/lineage/interfaces/power-libperfmgr \
    hardware/qcom-caf/common/libqti-perfd-client \
    vendor/qcom/opensource/usb/etc

# Telephony
PRODUCT_PACKAGES += \
    ims-ext-common \
    ims_ext_common.xml \
    qti-telephony-hidl-wrapper \
    qti_telephony_hidl_wrapper.xml \
    qti-telephony-utils \
    qti_telephony_utils.xml \
    telephony-ext

PRODUCT_BOOT_JARS += \
    telephony-ext

# BALMUDA gestures (parts/)
PRODUCT_PACKAGES += \
    BalmudaParts

# Tap to wake: ILITEK sends KEY_F3 on a touch, the BalmudaParts KeyHandler wakes on the second one
# (the Power HAL enables the gesture mode, powerhint.json)
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/keylayout/ILITEK_TDDI.kl:$(TARGET_COPY_OUT_VENDOR)/usr/keylayout/ILITEK_TDDI.kl

# IMS client permissions
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/configs/privapp-permissions-ims.xml:$(TARGET_COPY_OUT_SYSTEM_EXT)/etc/permissions/privapp-permissions-ims.xml

# Thermal
PRODUCT_PACKAGES += \
    android.hardware.thermal-service.qti

# USB
PRODUCT_PACKAGES += \
    android.hardware.usb-service.qti

# Vibrator (stock HAL)
PRODUCT_PACKAGES += \
    vendor.qti.hardware.vibrator.service_kyocera
# vendor/qcom/opensource/vibrator is removed from the tree (local manifest remove-project): same install paths;
# excluded-input-devices.xml comes from the stock blobs

# WiFi
PRODUCT_PACKAGES += \
    android.hardware.wifi-service \
    WifiOverlay \
    hostapd \
    libwifi-hal-ctrl \
    libwifi-hal-qcom \
    wpa_supplicant \
    wpa_supplicant.conf

PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/wifi/p2p_supplicant_overlay.conf:$(TARGET_COPY_OUT_VENDOR)/etc/wifi/p2p_supplicant_overlay.conf \
    $(LOCAL_PATH)/wifi/wpa_supplicant_overlay.conf:$(TARGET_COPY_OUT_VENDOR)/etc/wifi/wpa_supplicant_overlay.conf

# Proprietary blobs
$(call inherit-product, vendor/balmuda/A101BM/A101BM-vendor.mk)
