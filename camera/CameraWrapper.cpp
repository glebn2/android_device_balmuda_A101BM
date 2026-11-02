/*
 * SPDX-FileCopyrightText: The LineageOS Project
 * SPDX-License-Identifier: Apache-2.0
 */

// Wrapper around the stock CamX module (camera.qcom.so).
//
// The camera kernel driver stamps frames with CLOCK_BOOTTIME, but CamX declares
// android.sensor.info.timestampSource = UNKNOWN (monotonic). The framework then leaves
// video encoder timestamps as they are, while audio is MONOTONIC: after the phone has slept,
// video starts hours after audio and recordings get a huge duration with a frozen frame.
// Declaring REALTIME makes cameraservice convert timestamps for the encoder and composer.

#define LOG_TAG "CameraWrapper"

#include <dlfcn.h>
#include <mutex>
#include <unordered_map>

#include <hardware/camera_common.h>
#include <hardware/hardware.h>
#include <log/log.h>
#include <system/camera_metadata.h>

namespace {

constexpr char kStockModule[] = "/vendor/lib64/hw/camera.qcom.so";

camera_module_t* gStock;
std::mutex gLock;
std::unordered_map<int, camera_metadata_t*> gStatic;
std::unordered_map<int, camera_metadata_t*> gPhysical;

bool loadStock() {
    if (gStock) return true;
    void* handle = dlopen(kStockModule, RTLD_NOW);
    if (!handle) {
        ALOGE("dlopen %s: %s", kStockModule, dlerror());
        return false;
    }
    gStock = static_cast<camera_module_t*>(dlsym(handle, HAL_MODULE_INFO_SYM_AS_STR));
    if (!gStock) ALOGE("no %s in %s", HAL_MODULE_INFO_SYM_AS_STR, kStockModule);
    return gStock != nullptr;
}

// Returns a cached copy of the characteristics with timestampSource set to REALTIME.
camera_metadata_t* fixed(std::unordered_map<int, camera_metadata_t*>& cache, int id,
                         const camera_metadata_t* src) {
    if (!src) return nullptr;
    auto it = cache.find(id);
    if (it != cache.end()) return it->second;
    camera_metadata_t* copy = clone_camera_metadata(src);
    if (!copy) return nullptr;
    camera_metadata_entry_t entry;
    const uint8_t realtime = ANDROID_SENSOR_INFO_TIMESTAMP_SOURCE_REALTIME;
    if (find_camera_metadata_entry(copy, ANDROID_SENSOR_INFO_TIMESTAMP_SOURCE, &entry) == 0) {
        update_camera_metadata_entry(copy, entry.index, &realtime, 1, nullptr);
    }
    cache[id] = copy;
    return copy;
}

int open(const hw_module_t*, const char* id, hw_device_t** device) {
    if (!loadStock()) return -ENODEV;
    return gStock->common.methods->open(&gStock->common, id, device);
}

int getNumberOfCameras() {
    return loadStock() ? gStock->get_number_of_cameras() : 0;
}

int getCameraInfo(int id, struct camera_info* info) {
    if (!loadStock()) return -ENODEV;
    int ret = gStock->get_camera_info(id, info);
    if (ret == 0 && info) {
        std::lock_guard<std::mutex> lock(gLock);
        camera_metadata_t* meta = fixed(gStatic, id, info->static_camera_characteristics);
        if (meta) info->static_camera_characteristics = meta;
    }
    return ret;
}

int setCallbacks(const camera_module_callbacks_t* callbacks) {
    return loadStock() ? gStock->set_callbacks(callbacks) : -ENODEV;
}

void getVendorTagOps(vendor_tag_ops_t* ops) {
    if (loadStock() && gStock->get_vendor_tag_ops) gStock->get_vendor_tag_ops(ops);
}

int openLegacy(const hw_module_t*, const char* id, uint32_t halVersion, hw_device_t** device) {
    if (!loadStock() || !gStock->open_legacy) return -ENOSYS;
    return gStock->open_legacy(&gStock->common, id, halVersion, device);
}

int setTorchMode(const char* id, bool enabled) {
    if (!loadStock() || !gStock->set_torch_mode) return -ENOSYS;
    return gStock->set_torch_mode(id, enabled);
}

int init() {
    if (!loadStock()) return -ENODEV;
    return gStock->init ? gStock->init() : 0;
}

int getPhysicalCameraInfo(int id, camera_metadata_t** staticMetadata) {
    if (!loadStock() || !gStock->get_physical_camera_info) return -ENOSYS;
    int ret = gStock->get_physical_camera_info(id, staticMetadata);
    if (ret == 0 && staticMetadata) {
        std::lock_guard<std::mutex> lock(gLock);
        camera_metadata_t* meta = fixed(gPhysical, id, *staticMetadata);
        if (meta) *staticMetadata = meta;
    }
    return ret;
}

int isStreamCombinationSupported(int id, const camera_stream_combination_t* streams) {
    if (!loadStock() || !gStock->is_stream_combination_supported) return -ENOSYS;
    return gStock->is_stream_combination_supported(id, streams);
}

void notifyDeviceStateChange(uint64_t state) {
    if (loadStock() && gStock->notify_device_state_change) gStock->notify_device_state_change(state);
}

hw_module_methods_t gMethods = {
    .open = open,
};

}  // namespace

extern "C" {
// Versions are copied from the stock module in the constructor below.
camera_module_t HAL_MODULE_INFO_SYM = {
    .common = {
        .tag = HARDWARE_MODULE_TAG,
        .module_api_version = CAMERA_MODULE_API_VERSION_2_4,
        .hal_api_version = HARDWARE_HAL_API_VERSION,
        .id = CAMERA_HARDWARE_MODULE_ID,
        .name = "BALMUDA Phone camera wrapper",
        .author = "The LineageOS Project",
        .methods = &gMethods,
    },
    .get_number_of_cameras = getNumberOfCameras,
    .get_camera_info = getCameraInfo,
    .set_callbacks = setCallbacks,
    .get_vendor_tag_ops = getVendorTagOps,
    .open_legacy = openLegacy,
    .set_torch_mode = setTorchMode,
    .init = init,
    .get_physical_camera_info = getPhysicalCameraInfo,
    .is_stream_combination_supported = isStreamCombinationSupported,
    .notify_device_state_change = notifyDeviceStateChange,
};
}

__attribute__((constructor)) static void copyVersions() {
    if (!loadStock()) return;
    HAL_MODULE_INFO_SYM.common.module_api_version = gStock->common.module_api_version;
    HAL_MODULE_INFO_SYM.common.hal_api_version = gStock->common.hal_api_version;
    if (!gStock->open_legacy) HAL_MODULE_INFO_SYM.open_legacy = nullptr;
    if (!gStock->set_torch_mode) HAL_MODULE_INFO_SYM.set_torch_mode = nullptr;
    if (!gStock->init) HAL_MODULE_INFO_SYM.init = nullptr;
    if (!gStock->get_physical_camera_info) HAL_MODULE_INFO_SYM.get_physical_camera_info = nullptr;
    if (!gStock->is_stream_combination_supported)
        HAL_MODULE_INFO_SYM.is_stream_combination_supported = nullptr;
    if (!gStock->notify_device_state_change)
        HAL_MODULE_INFO_SYM.notify_device_state_change = nullptr;
}
