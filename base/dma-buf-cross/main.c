#include <stdio.h>
#include <assert.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <unistd.h>
#include <fcntl.h>
#include <xf86drm.h>
#include <xf86drmMode.h>

#include <gbm.h>

int
main(int argc, char **argv)
{
	int lima_fd = drmOpen("lima", NULL);
	//int lima_fd = open("/dev/dri/renderD128", O_RDWR);
	assert(lima_fd >= 0);

	int kms_fd = drmOpen("sun4i-drm", NULL);
	assert(kms_fd);

	uint64_t cap = 0;
	assert(!drmGetCap(lima_fd, DRM_CAP_PRIME, &cap));
	assert((cap & DRM_PRIME_CAP_IMPORT) && (cap & DRM_PRIME_CAP_EXPORT));

	cap = 0;
	assert(!drmGetCap(kms_fd, DRM_CAP_PRIME, &cap));
	assert((cap & DRM_PRIME_CAP_IMPORT) && (cap & DRM_PRIME_CAP_EXPORT));

	drmModeResPtr res = drmModeGetResources(kms_fd);
	assert(res);

	drmModeConnectorPtr connector = NULL;
	for (int i = 0; i < res->count_connectors; i++) {
		connector = drmModeGetConnector(kms_fd, res->connectors[i]);
		assert(connector);

		if (connector->connection == DRM_MODE_CONNECTED)
			break;

		drmFree(connector);
	}

	drmModeEncoderPtr encoder = drmModeGetEncoder(kms_fd, connector->encoder_id);
	assert(encoder);

	drmModeCrtcPtr crtc = drmModeGetCrtc(kms_fd, encoder->crtc_id);
	assert(crtc);

	drmModeFBPtr fb = drmModeGetFB(kms_fd, crtc->buffer_id);
	assert(fb);

	drmModePlaneResPtr plane_res = drmModeGetPlaneResources(kms_fd);
	assert(plane_res);

	drmModePlanePtr plane = NULL;
	for (int i = 0; i < plane_res->count_planes; i++) {
		plane = drmModeGetPlane(kms_fd, plane_res->planes[i]);
		assert(plane);

		if (plane->fb_id == fb->fb_id)
			break;

		drmFree(plane);
	}

	uint64_t has_dumb;
	assert(!drmGetCap(lima_fd, DRM_CAP_DUMB_BUFFER, &has_dumb));
	assert(has_dumb);

	struct drm_mode_create_dumb creq;
	memset(&creq, 0, sizeof(creq));
	creq.width = fb->width;
	creq.height = fb->height;
	creq.bpp = fb->bpp;
	assert(!drmIoctl(lima_fd, DRM_IOCTL_MODE_CREATE_DUMB, &creq));

	printf("width=%d height=%d bpp=%d pitch=%d size=%d\n",
	       creq.width, creq.height, creq.bpp, creq.pitch, creq.size);

	struct drm_mode_map_dumb mreq;
	memset(&mreq, 0, sizeof(mreq));
	mreq.handle = creq.handle;
	assert(!drmIoctl(lima_fd, DRM_IOCTL_MODE_MAP_DUMB, &mreq));

	uint32_t *map = mmap(0, creq.size, PROT_READ | PROT_WRITE, MAP_SHARED,
			     lima_fd, mreq.offset);
	assert(map != MAP_FAILED);
	memset(map, 0, creq.size);

	for (int i = 230; i < 600; i++)
		for (int j = 100; j < 300; j++)
			map[i * (creq.pitch >> 2) + j] = 0x12345678;

	assert(!munmap(map, creq.size));

	int prime_fd;
	assert(!drmPrimeHandleToFD(lima_fd, creq.handle, DRM_CLOEXEC, &prime_fd) && prime_fd);

	uint32_t handle;
	assert(!drmPrimeFDToHandle(kms_fd, prime_fd, &handle));

	uint32_t my_fb;
	assert(!drmModeAddFB(kms_fd, creq.width, creq.height, 24, creq.bpp,
			     creq.pitch, handle, &my_fb));

	assert(!drmModeSetCrtc(kms_fd, crtc->crtc_id, my_fb, 0, 0, &connector->connector_id,
			       1, &crtc->mode));

	sleep(10);

	assert(!drmModeSetCrtc(kms_fd, crtc->crtc_id, fb->fb_id, 0, 0, &connector->connector_id,
			       1, &crtc->mode));

	assert(!drmModeRmFB(kms_fd, my_fb));
	struct drm_mode_destroy_dumb dreq;
	memset(&dreq, 0, sizeof(dreq));
	dreq.handle = creq.handle;
	assert(!drmIoctl(lima_fd, DRM_IOCTL_MODE_DESTROY_DUMB, &dreq));

	drmFree(plane);
	drmFree(plane_res);
	drmFree(fb);
	drmFree(crtc);
	drmFree(encoder);
	drmFree(connector);
	drmFree(res);
	drmClose(lima_fd);
	drmClose(kms_fd);
	
	return 0;
}
