#!/usr/bin/env -S PYTHONPATH=../../../tools/extract-utils python3
#
# SPDX-FileCopyrightText: The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#
# Usage: ./extract-files.py <dir with the stock vendor/, odm/ and system_ext/>
#

from extract_utils.fixups_blob import (
    blob_fixup,
    blob_fixups_user_type,
)
from extract_utils.fixups_lib import (
    lib_fixups,
    lib_fixups_user_type,
)
from extract_utils.main import (
    ExtractUtils,
    ExtractUtilsModule,
)

namespace_imports = [
    'device/balmuda/A101BM',
    'hardware/qcom-caf/common/libqti-perfd-client',
    'hardware/qcom-caf/sm8250',
    'hardware/qcom-caf/wlan',
    'hardware/qcom-caf/wlan/qcwcn',
    'vendor/qcom/opensource/dataservices',
    'vendor/qcom/opensource/display',
]


lib_fixups: lib_fixups_user_type = {
    **lib_fixups,
    # Stock vibrator HAL links to its own suffixed modules
    (
        'vendor.qti.hardware.vibrator.impl',
        'libqtivibratoreffect',
    ): lambda lib, *args, **kwargs: f'{lib}_kyocera',
}

blob_fixups: blob_fixups_user_type = {
    'vendor/etc/init/vendor.qti.hardware.alarm@1.0-service.rc': blob_fixup()
        .regex_replace('    disabled', ''),
    'vendor/bin/hw/android.hardware.lights-service.qti': blob_fixup()
        .replace_needed('android.hardware.light-V1-ndk_platform.so', 'android.hardware.light-V1-ndk.so'),
    (
        'vendor/bin/hw/vendor.qti.hardware.vibrator.service',
        'vendor/lib64/vendor.qti.hardware.vibrator.impl.so',
    ): blob_fixup()
        .replace_needed('android.hardware.vibrator-V1-ndk_platform.so', 'android.hardware.vibrator-V1-ndk.so'),
    'vendor/lib64/libdpps.so': blob_fixup()
        .replace_needed('libtinyxml2.so', 'libtinyxml2-v34.so'),
    (
        'vendor/lib64/libwvhidl.so',
        'vendor/lib/mediadrm/libwvdrmengine.so',
        'vendor/lib64/mediadrm/libwvdrmengine.so',
    ): blob_fixup()
        .add_needed('libcrypto_shim.so'),
    # libbase only provides the string_view variant of android::base::Trim
    (
        'vendor/lib64/ese_spi_nxp.so',
        'vendor/lib64/nfc_nci_nxp.so',
        'vendor/lib64/ls_client.so',
    ): blob_fixup()
        .add_needed('libbase_shim.so'),
}  # fmt: skip

module = ExtractUtilsModule(
    'A101BM',
    'balmuda',
    blob_fixups=blob_fixups,
    lib_fixups=lib_fixups,
    namespace_imports=namespace_imports,
)
# IMS client
module.add_proprietary_file('proprietary-files-ims.txt')
# Stock vibrator HAL
module.add_proprietary_file('proprietary-files-vibrator.txt')

if __name__ == '__main__':
    utils = ExtractUtils.device(module)
    utils.run()
