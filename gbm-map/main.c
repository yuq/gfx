#include <stdio.h>
#include <stdlib.h>
#include <assert.h>

#include <fcntl.h>
#include <unistd.h>

#include <gbm.h>

int main(void)
{
        int fd = open("/dev/dri/card0", O_RDWR);
	//int fd = open("/dev/dri/renderD128", O_RDWR);
	assert(fd >= 0);

	struct gbm_device *gbm = gbm_create_device(fd);
	assert(gbm != NULL);

	struct gbm_bo *bo = gbm_bo_create(
		gbm, 1920, 1080, GBM_FORMAT_ARGB8888,
		GBM_BO_USE_RENDERING|GBM_BO_USE_SCANOUT|GBM_BO_USE_LINEAR);
	assert(bo);

	uint32_t stride;
	void *data;
	void *map = gbm_bo_map(bo, 0, 0, 1920, 1080, GBM_BO_TRANSFER_READ_WRITE, &stride, &data);
	assert(map);

	printf("map=%x %p\n", *(unsigned *)map, map);
	
	gbm_bo_unmap(bo, data);
	
	return 0;
}
