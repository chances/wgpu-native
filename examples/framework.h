#include "wgpu.h"

WGPUShaderModuleDescriptor load_wgsl(const char *name);

void request_adapter_callback(WGPURequestAdapterStatus status, WGPUAdapter received, char* message, void* userdata);

void request_device_callback(WGPURequestDeviceStatus status, WGPUDevice received, char* message, void* userdata);

void readBufferMap(WGPUBufferMapAsyncStatus status, uint8_t* userdata);

void initializeLog();

