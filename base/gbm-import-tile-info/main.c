#include <stdio.h>
#include <stdlib.h>
#include <assert.h>

#include <fcntl.h>
#include <unistd.h>

#include <gbm.h>
#include <libdrm/amdgpu.h>

struct gbm_bo {
  struct gbm_device *gbm;
  uint32_t width;
  uint32_t height;
  uint32_t stride;
  uint32_t format;
  union gbm_bo_handle  handle;
  void *user_data;
  void (*destroy_user_data)(struct gbm_bo *, void *);
};

struct gbm_drm_bo {
  struct gbm_bo base;
};

struct gbm_amdgpu_bo {
  struct gbm_drm_bo  base;
  amdgpu_bo_handle bo;
};

struct context {
  struct gbm_device *gbm;
  const char *dev;
  struct gbm_bo *bo;
};

#define TARGET_SIZE 256

void GBMInit(struct context *ctx)
{
  int fd = open(ctx->dev, O_RDWR);
  assert(fd >= 0);

  ctx->gbm = gbm_create_device(fd);
  assert(ctx->gbm != NULL);
}

void ExportBO(struct context *export, struct context *import)
{
  export->bo = gbm_bo_create(export->gbm, TARGET_SIZE, TARGET_SIZE, 
			     GBM_FORMAT_ARGB8888, 
			     GBM_BO_USE_LINEAR |
			     GBM_BO_USE_RENDERING |
			     GBM_BO_USE_SCANOUT);
  int fd = gbm_bo_get_fd(export->bo);
  struct gbm_import_fd_data data;
  data.fd = fd;
  data.width = gbm_bo_get_width(export->bo);
  data.height = gbm_bo_get_height(export->bo);
  data.stride = gbm_bo_get_stride(export->bo);
  import->bo = gbm_bo_import(import->gbm, GBM_BO_IMPORT_FD, &data, 0);

  struct gbm_amdgpu_bo *amd_bo = (struct gbm_amdgpu_bo *)import->bo;
  struct amdgpu_bo_info info = {0};
  assert(amdgpu_bo_query_info(amd_bo->bo, &info) == 0);
  printf("alloc_size=%llx phys_alignment=%llx preferred_heap=%d alloc_flags=%llx\n",
	 info.alloc_size, info.phys_alignment, info.preferred_heap, info.alloc_flags);
  printf("metadata flags=%llx tiling_info=%llx size_metadata=%d\n",
	 info.metadata.flags, info.metadata.tiling_info, info.metadata.size_metadata);

  int i;
  printf("umd metadata\n");
  for (i = 0; i < info.metadata.size_metadata/4; i++)
    printf("%x\n", info.metadata.umd_metadata[i]);
}

int main(void)
{
  struct context master, slave;

  master.dev = "/dev/dri/card1";
  slave.dev = "/dev/dri/card0";

  GBMInit(&master);
  GBMInit(&slave);
  
  ExportBO(&master, &slave);
  
  return 0;
}


