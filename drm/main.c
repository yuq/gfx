#include <stdio.h>
#include <assert.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <unistd.h>
#include <xf86drm.h>
#include <xf86drmMode.h>

int main(int argc, char **argv)
{
	int fd = drmOpen("radeon", NULL);
	assert(fd >= 0);

	// expose all planes including primary and cursor planes
	assert(!drmSetClientCap(fd, DRM_CLIENT_CAP_UNIVERSAL_PLANES, 1));

	drmModeResPtr res = drmModeGetResources(fd);
	assert(res);

	int i, j;
	drmModeConnectorPtr connector = NULL;
	for (i = 0; i < res->count_connectors; i++) {
		connector = drmModeGetConnector(fd, res->connectors[i]);
		assert(connector);

		if (connector->connection == DRM_MODE_CONNECTED)
			break;

		drmFree(connector);
	}

	drmModeEncoderPtr encoder = drmModeGetEncoder(fd, connector->encoder_id);
	assert(encoder);

	drmModeCrtcPtr crtc = drmModeGetCrtc(fd, encoder->crtc_id);
	assert(crtc);

	drmModeFBPtr fb = drmModeGetFB(fd, crtc->buffer_id);
    assert(fb);

	drmModePlaneResPtr plane_res = drmModeGetPlaneResources(fd);
	assert(plane_res);

	drmModePlanePtr plane = NULL;
	for (i = 0; i < plane_res->count_planes; i++) {
		plane = drmModeGetPlane(fd, plane_res->planes[i]);
		assert(plane);

		if (plane->fb_id == fb->fb_id)
			break;

		drmFree(plane);
	}

	uint64_t has_dumb;
	assert(!drmGetCap(fd, DRM_CAP_DUMB_BUFFER, &has_dumb));
	assert(has_dumb);

	struct drm_mode_create_dumb creq;
	memset(&creq, 0, sizeof(creq));
	creq.width = fb->width;
	creq.height = fb->height;
	creq.bpp = fb->bpp;
	assert(!drmIoctl(fd, DRM_IOCTL_MODE_CREATE_DUMB, &creq));

	printf("width=%d height=%d bpp=%d pitch=%d size=%d\n",
		   creq.width, creq.height, creq.bpp, creq.pitch, creq.size);

	uint32_t my_fb;
	assert(!drmModeAddFB(fd, creq.width, creq.height, 24, creq.bpp, creq.pitch, creq.handle, &my_fb));	

	struct drm_mode_map_dumb mreq;
	memset(&mreq, 0, sizeof(mreq));
	mreq.handle = creq.handle;
	assert(!drmIoctl(fd, DRM_IOCTL_MODE_MAP_DUMB, &mreq));

	uint32_t *map = mmap(0, creq.size, PROT_READ | PROT_WRITE, MAP_SHARED, fd, mreq.offset);
	assert(map != MAP_FAILED);
	memset(map, 0, creq.size);

	for (i = 100; i < 500; i++)
		for (j = 200; j < 460; j++)
			map[i * (creq.pitch >> 2) + j] = 0x12345678;

	assert(!drmModeSetCrtc(fd, crtc->crtc_id, my_fb, 0, 0, &connector->connector_id, 1, &crtc->mode));
	sleep(10);
	assert(!drmModeSetCrtc(fd, crtc->crtc_id, fb->fb_id, 0, 0, &connector->connector_id, 1, &crtc->mode));

	assert(!drmModeRmFB(fd, my_fb));
	struct drm_mode_destroy_dumb dreq;
	memset(&dreq, 0, sizeof(dreq));
	dreq.handle = creq.handle;
	assert(!drmIoctl(fd, DRM_IOCTL_MODE_DESTROY_DUMB, &dreq));

	drmFree(plane);
	drmFree(plane_res);
	drmFree(fb);
	drmFree(crtc);
	drmFree(encoder);
	drmFree(connector);
	drmFree(res);
	drmClose(fd);
	return 0;
}
















