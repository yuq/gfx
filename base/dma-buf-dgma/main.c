#include <stdio.h>
#include <assert.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <unistd.h>
#include <fcntl.h>

#include <xf86drm.h>
#include <libdrm/amdgpu.h>
#include <libdrm/amdgpu_drm.h>

#define BUFF_SIZE 0x100000

int
main(int argc, char **argv)
{
	char *f1 = "/dev/dri/renderD128";
	char *f2 = "/dev/dri/renderD128";
	if (argc > 1) {
		f1 = argv[1];
		if (argc > 2)
			f2 = argv[2];
	}

	int gpu0_fd = open(f1, O_RDWR);
	assert(gpu0_fd >= 0);

	int gpu1_fd = open(f2, O_RDWR);
	assert(gpu1_fd);

	uint64_t cap = 0;
	assert(!drmGetCap(gpu0_fd, DRM_CAP_PRIME, &cap));
	assert((cap & DRM_PRIME_CAP_IMPORT) && (cap & DRM_PRIME_CAP_EXPORT));

	cap = 0;
	assert(!drmGetCap(gpu1_fd, DRM_CAP_PRIME, &cap));
	assert((cap & DRM_PRIME_CAP_IMPORT) && (cap & DRM_PRIME_CAP_EXPORT));

	uint32_t major_version, minor_version;
	amdgpu_device_handle dev0, dev1;
	assert(!amdgpu_device_initialize(gpu0_fd, &major_version, &minor_version, &dev0));
	assert(!amdgpu_device_initialize(gpu1_fd, &major_version, &minor_version, &dev1));

	amdgpu_bo_handle bo0;
	struct amdgpu_bo_alloc_request req = {
		.alloc_size = BUFF_SIZE,
		.phys_alignment = 256,
		.preferred_heap = AMDGPU_GEM_DOMAIN_VRAM,
		.flags = AMDGPU_GEM_CREATE_CPU_ACCESS_REQUIRED,
	};
	assert(!amdgpu_bo_alloc(dev0, &req, &bo0));

	void *cpu0;
	assert(!amdgpu_bo_cpu_map(bo0, &cpu0));

	int prime_fd;
	assert(!amdgpu_bo_export(bo0, amdgpu_bo_handle_type_dma_buf_fd, &prime_fd));

	struct amdgpu_bo_import_result result = {0};
	assert(!amdgpu_bo_import(dev1, amdgpu_bo_handle_type_dma_buf_fd, prime_fd, &result));
	amdgpu_bo_handle bo1 = result.buf_handle;
	assert(result.alloc_size == BUFF_SIZE);

	void *cpu1;
	assert(!amdgpu_bo_cpu_map(bo1, &cpu1));

	for (int i = 0; i < BUFF_SIZE / 4; i++)
		((uint32_t *)cpu0)[i] = i;

	for (int i = 0; i < BUFF_SIZE / 4; i++) {
		uint32_t data = ((uint32_t *)cpu1)[i];
		if (data != i) {
			printf("check buffer failed at %d: %x\n", i, data);
			return 0;
		}
	}
	printf("check buffer success\n");
	
	return 0;
}
