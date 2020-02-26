#include <stdio.h>
#include <stdlib.h>
#include <assert.h>

#include <fcntl.h>
#include <unistd.h>

#include <gbm.h>

int main(void)
{
	//int fd = open("/dev/dri/card0", O_RDWR);
	int fd = open("/dev/dri/renderD128", O_RDWR);
	assert(fd >= 0);

	struct gbm_device *gbm = gbm_create_device(fd);
	assert(gbm != NULL);

	struct gbm_bo *bo = gbm_bo_create(
		gbm, 1280, 720, GBM_FORMAT_ARGB8888,
		GBM_BO_USE_RENDERING|GBM_BO_USE_LINEAR);
	assert(bo);

	for (int i = 0; i < 100; i++) {
		uint32_t stride = 0;
		void *data = NULL;
		void *map = gbm_bo_map(bo, 0, 0, 1280, 720, GBM_BO_TRANSFER_READ, &stride, &data);
		assert(map);

		usleep(50000);
		printf("i=%d\n", i);
	
		gbm_bo_unmap(bo, data);

		usleep(50000);
	}
	
	return 0;
}
