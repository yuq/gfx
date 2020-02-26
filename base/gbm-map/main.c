#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>

#include <fcntl.h>
#include <unistd.h>
#include <time.h>

#include <gbm.h>

#define TARGET_W 1024
#define TARGET_H 1024

void copy_one(const char *name, void *dst, void *src, int size)
{
	struct timespec tv1, tv2;
	assert(!clock_gettime(CLOCK_MONOTONIC_RAW, &tv1));

	memcpy(dst, src, size);

	assert(!clock_gettime(CLOCK_MONOTONIC_RAW, &tv2));

	double start = tv1.tv_sec;
	start = start * 1e9 + tv1.tv_nsec;

	double end = tv2.tv_sec;
	end = end * 1e9 + tv2.tv_nsec;

	double rate = size / (end - start);
	printf("%s copy rate %f GB/s\n", name, rate);
}

int main(void)
{
	int size = TARGET_W * TARGET_H * 4;
	void *dst = malloc(size);
	assert(dst);
	void *src = malloc(size);
	assert(src);

	for (int i = 0; i < 10; i++) {
		copy_one("mem", dst, src, size);
	}

	int fd = open("/dev/dri/renderD128", O_RDWR);
	assert(fd >= 0);

	struct gbm_device *gbm = gbm_create_device(fd);
	assert(gbm != NULL);

	struct gbm_bo *bo = gbm_bo_create(
		gbm, TARGET_W, TARGET_H, GBM_FORMAT_ARGB8888,
		GBM_BO_USE_RENDERING|GBM_BO_USE_LINEAR);
	assert(bo);

	uint32_t stride = 0;
	void *data = NULL;
	void *map = gbm_bo_map(bo, 0, 0, TARGET_W, TARGET_H,
			       GBM_BO_TRANSFER_READ, &stride,
			       &data);
	assert(map);

	for (int i = 0; i < 10; i++) {
		copy_one("gbm", dst, map, size);
	}

	gbm_bo_unmap(bo, data);
	
	return 0;
}
