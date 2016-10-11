#include <stdio.h>
#include <assert.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <unistd.h>
#include <xf86drm.h>
#include <xf86drmMode.h>
#include <libdrm/amdgpu.h>
#include <libdrm/amdgpu_drm.h>

int main(int argc, char **argv)
{
  drmDevicePtr devs[10];
  int numdev;

  numdev = drmGetDevices(devs, 10);
  assert(numdev > 0);

  int i;
  for (i = 0; i < numdev; i++) {
    printf("==========================\n");
    if (devs[i]->available_nodes & (1 << DRM_NODE_PRIMARY))
      printf("node primary: %s\n", devs[i]->nodes[DRM_NODE_PRIMARY]);
    if (devs[i]->available_nodes & (1 << DRM_NODE_CONTROL))
      printf("node control: %s\n", devs[i]->nodes[DRM_NODE_CONTROL]);
    if (devs[i]->available_nodes & (1 << DRM_NODE_RENDER))
      printf("node render: %s\n", devs[i]->nodes[DRM_NODE_RENDER]);
    printf("bus type pci: %s\n", devs[i]->bustype == DRM_BUS_PCI ? "yes" : "no");
    if (devs[i]->bustype == DRM_BUS_PCI) {
      printf("domain=%d bus=%d dev=%d func=%d\n",
	     devs[i]->businfo.pci->domain,
	     devs[i]->businfo.pci->bus,
	     devs[i]->businfo.pci->dev,
	     devs[i]->businfo.pci->func);
      printf("vendor=%x device=%x subvendor=%x subdevice=%x revision=%x\n",
	     devs[i]->deviceinfo.pci->vendor_id,
	     devs[i]->deviceinfo.pci->device_id,
	     devs[i]->deviceinfo.pci->subvendor_id,
	     devs[i]->deviceinfo.pci->subdevice_id,
	     devs[i]->deviceinfo.pci->revision_id);
    }
  }
  drmFreeDevices(devs, numdev);

  assert(argc > 1);
  int fd = drmOpen(argv[1], NULL);
  assert(fd >= 0);

  printf("++++++++++++++++++++++\n");
  printf("dev %s bus id %s\n", argv[1], drmGetBusid(fd));

  drm_unique_t u = {0};
  int ret = drmIoctl(fd, DRM_IOCTL_GET_UNIQUE, &u);
  printf("ret = %d\n", ret);
  u.unique = drmMalloc(u.unique_len + 1);
  ret = drmIoctl(fd, DRM_IOCTL_GET_UNIQUE, &u);
  u.unique[u.unique_len] = '\0';
  printf("ret = %d len = %lu\n", ret, u.unique_len);

  uint32_t major_version, minor_version;
  amdgpu_device_handle device_handle;
  assert(!amdgpu_device_initialize(fd, &major_version, &minor_version, &device_handle));

  amdgpu_bo_handle buf_handle;
  struct amdgpu_bo_alloc_request req = {0};
  req.alloc_size = 385024;
  req.phys_alignment = 256;
  req.preferred_heap = AMDGPU_GEM_DOMAIN_VRAM;
  req.flags = AMDGPU_GEM_CREATE_NO_CPU_ACCESS;
  assert(!amdgpu_bo_alloc(device_handle, &req, &buf_handle));

  struct amdgpu_bo_info info;
  assert(!amdgpu_bo_query_info(buf_handle, &info));
  printf("heap=%d flags=%lx\n", info.preferred_heap, info.alloc_flags);
  
  uint32_t shared_handle;
  assert(!amdgpu_bo_export(buf_handle, amdgpu_bo_handle_type_gem_flink_name, &shared_handle));
  printf("flink name = %x\n", shared_handle);

  assert(!amdgpu_bo_query_info(buf_handle, &info));
  printf("heap=%d flags=%lx\n", info.preferred_heap, info.alloc_flags);

  int prime_fd;
  assert(!amdgpu_bo_export(buf_handle, amdgpu_bo_handle_type_dma_buf_fd, &prime_fd));
  printf("dma fd = %d\n", prime_fd);

  assert(!amdgpu_bo_query_info(buf_handle, &info));
  printf("heap=%d flags=%lx\n", info.preferred_heap, info.alloc_flags);

  if (argc > 2) {
    int fd = drmOpen(argv[2], NULL);
    assert(fd >= 0);

    uint32_t prime_handle;
    assert(!drmPrimeFDToHandle(fd, prime_fd, &prime_handle));

    assert(!amdgpu_bo_query_info(buf_handle, &info));
    printf("heap=%d flags=%lx\n", info.preferred_heap, info.alloc_flags);
  }
  
  amdgpu_bo_free(buf_handle);
  drmClose(fd);
  return 0;
}
















