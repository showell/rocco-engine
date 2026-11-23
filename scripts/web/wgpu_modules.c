// One WebGPU shader module for each distinct WGSL source. sokol makes a
// module for each stage of each sg_shader, and many of the engine's shaders
// share a stage's source: the full screen triangle of the bloom and post
// passes, a mesh shader's vertex stage under its opaque, mask and blend
// fragments, a game shader's stages across its layouts. A browser compiles
// each module it is given, so a page waits for every copy before its first
// frame. build-host.sh compiles sokol_gfx.c with wgpuDeviceCreateShaderModule
// renamed to rocco_wgpu_create_shader_module, which hands back the module
// already made for the same source and device, with a reference of its own.
// WebGPU keys a module on its code alone (a pipeline names the entry point),
// so a shared module behaves as a copy would. The first module's label stays.
#include <stdint.h>
#include <string.h>
#include <stdlib.h>
#include <webgpu/webgpu.h>

// The engine and a game's shader packs make about 90 modules, from about 50
// sources. A source past the table gets a module of its own, as before.
#define ROCCO_WGPU_MODULE_LIMIT 512

typedef struct rocco_wgpu_module {
	WGPUDevice device;
	uint64_t hash;
	size_t length;
	char *code;
	WGPUShaderModule module;
} rocco_wgpu_module;

// The table holds a reference to each module, so a module outlives the
// shaders that sokol destroys and a later shader with its source reuses it.
static rocco_wgpu_module rocco_wgpu_modules[ROCCO_WGPU_MODULE_LIMIT];
static int rocco_wgpu_module_count;

// FNV-1a, to pass over most entries without comparing their code.
static uint64_t rocco_wgpu_hash(const char *code, size_t length) {
	uint64_t hash = 14695981039346656037ull;
	for (size_t i = 0; i < length; i++) {
		hash = (hash ^ (uint8_t)code[i]) * 1099511628211ull;
	}
	return hash;
}

static const WGPUShaderSourceWGSL *rocco_wgpu_wgsl(const WGPUShaderModuleDescriptor *descriptor) {
	for (const WGPUChainedStruct *chain = descriptor->nextInChain; chain; chain = chain->next) {
		if (chain->sType == WGPUSType_ShaderSourceWGSL) {
			return (const WGPUShaderSourceWGSL *)chain;
		}
	}
	return NULL;
}

WGPUShaderModule rocco_wgpu_create_shader_module(WGPUDevice device, const WGPUShaderModuleDescriptor *descriptor) {
	const WGPUShaderSourceWGSL *wgsl = rocco_wgpu_wgsl(descriptor);
	// Only WGSL with no other chained options is keyed by its code alone.
	if (!wgsl || !wgsl->code.data || descriptor->nextInChain != &wgsl->chain || wgsl->chain.next) {
		return wgpuDeviceCreateShaderModule(device, descriptor);
	}
	size_t length = wgsl->code.length == WGPU_STRLEN ? strlen(wgsl->code.data) : wgsl->code.length;
	uint64_t hash = rocco_wgpu_hash(wgsl->code.data, length);
	for (int i = 0; i < rocco_wgpu_module_count; i++) {
		rocco_wgpu_module *m = &rocco_wgpu_modules[i];
		if (m->device == device && m->hash == hash && m->length == length && memcmp(m->code, wgsl->code.data, length) == 0) {
			wgpuShaderModuleAddRef(m->module);
			return m->module;
		}
	}
	WGPUShaderModule module = wgpuDeviceCreateShaderModule(device, descriptor);
	if (!module || rocco_wgpu_module_count == ROCCO_WGPU_MODULE_LIMIT) {
		return module;
	}
	char *code = malloc(length);
	if (!code) {
		return module;
	}
	memcpy(code, wgsl->code.data, length);
	wgpuShaderModuleAddRef(module);
	rocco_wgpu_modules[rocco_wgpu_module_count++] = (rocco_wgpu_module){device, hash, length, code, module};
	return module;
}
