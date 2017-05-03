#include <stdio.h>
#include <assert.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <errno.h>
#include <time.h>

#include <xf86drm.h>
#include <xf86drmMode.h>
#include <libdrm/amdgpu.h>
#include <libdrm/amdgpu_drm.h>

#ifndef AMDGPU_GEM_DOMAIN_DGMA
#define AMDGPU_GEM_DOMAIN_DGMA          0x40
#endif

int main(int argc, char **argv)
{
  assert(argc > 2);

  int fd = open(argv[1], O_RDWR);
  assert(fd >= 0);

  uint32_t major_version, minor_version;
  amdgpu_device_handle device_handle;
  assert(!amdgpu_device_initialize(fd, &major_version, &minor_version, &device_handle));

  struct drm_amdgpu_capability cap;
  assert(!amdgpu_query_capability(device_handle, &cap));
  assert(cap.flag & AMDGPU_CAPABILITY_SSG_FLAG);
  
  amdgpu_bo_handle buf_handle;
  struct amdgpu_bo_alloc_request req = {0};
  req.alloc_size = 0x2000000;
  req.phys_alignment = 4096;
  //req.preferred_heap = AMDGPU_GEM_DOMAIN_VRAM;
  //req.preferred_heap = AMDGPU_GEM_DOMAIN_GTT;
  //req.flags = AMDGPU_GEM_CREATE_CPU_ACCESS_REQUIRED;
  req.preferred_heap = AMDGPU_GEM_DOMAIN_DGMA;
  assert(!amdgpu_bo_alloc(device_handle, &req, &buf_handle));

  int fd2 = open(argv[2], O_RDWR | O_DIRECT);
  assert(fd2 >= 0);

  void *cpu;
  assert(!amdgpu_bo_cpu_map(buf_handle, &cpu));
  printf("cpu addr=%p\n", cpu);

  int i, size;
  for (i = 0; i < 10; i++) {
    struct timespec ts1, ts2;
    assert(!clock_gettime(CLOCK_MONOTONIC, &ts1));
    size = read(fd2, cpu, 0x2000000);
    assert(!clock_gettime(CLOCK_MONOTONIC, &ts2));
    printf("read %x errno=%d\n", size, errno);

    double a = ts2.tv_sec - ts1.tv_sec;
    double b = ts2.tv_nsec - ts1.tv_nsec;
    double c = 32.0 / (a + b / 1000000000.0);
    printf("speed = %f MB/s\n", c);

    lseek(fd2, 0, SEEK_SET);
  }
  
  close(fd2);

  unsigned int *bp = cpu;
  printf("bo content %x %x %x %x %x %x %x %x %x %x %x %x %x %x %x %x\n",
	 bp[0], bp[1], bp[2], bp[3], bp[4], bp[5], bp[6], bp[7],
	 bp[8], bp[9], bp[10], bp[11], bp[12], bp[13], bp[14], bp[15]);

  if (argc > 3) {
    int fd3 = open(argv[3], O_RDWR | O_DIRECT);
    assert(fd3 >= 0);
    size = write(fd3, cpu, 0x100000);
    printf("write %x errno=%d\n", size, errno);
    close(fd3);
  }

  amdgpu_bo_free(buf_handle);
  drmClose(fd);
  return 0;
}
















