#include <stdio.h>
#include <assert.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/types.h>
#include <sys/stat.h>

#include <xf86drm.h>
#include <xf86drmMode.h>
#include <libdrm/amdgpu.h>
#include <libdrm/amdgpu_drm.h>

int main(int argc, char **argv)
{
  assert(argc > 2);

  int fd = drmOpen(argv[1], NULL);
  assert(fd >= 0);

  uint32_t major_version, minor_version;
  amdgpu_device_handle device_handle;
  assert(!amdgpu_device_initialize(fd, &major_version, &minor_version, &device_handle));

  amdgpu_bo_handle buf_handle;
  struct amdgpu_bo_alloc_request req = {0};
  req.alloc_size = 0x400000;
  req.phys_alignment = 4096;
  req.preferred_heap = AMDGPU_GEM_DOMAIN_VRAM;
  req.flags = AMDGPU_GEM_CREATE_CPU_ACCESS_REQUIRED;
  assert(!amdgpu_bo_alloc(device_handle, &req, &buf_handle));

  struct amdgpu_bo_info info;
  assert(!amdgpu_bo_query_info(buf_handle, &info));
  printf("heap=%d flags=%lx\n", info.preferred_heap, info.alloc_flags);

  void *cpu;
  assert(!amdgpu_bo_cpu_map(buf_handle, &cpu));
  printf("cpu addr=%p\n", cpu);
  printf("heap=%d flags=%lx\n", info.preferred_heap, info.alloc_flags);

  int fd2 = open(argv[2], O_RDWR | O_DIRECT);
  assert(fd >= 0);

  int size = read(fd2, cpu, 0x100000);
  printf("read %x\n", size);
  
  close(fd2);
  
  assert(!amdgpu_bo_query_info(buf_handle, &info));
  printf("heap=%d flags=%lx\n", info.preferred_heap, info.alloc_flags);

  amdgpu_bo_free(buf_handle);
  drmClose(fd);
  return 0;
}
















