#include <stdio.h>
#include <assert.h>
#include <stdlib.h>
#include <xf86drm.h>
#include <xf86drmMode.h>

int main(int argc, char **argv)
{
	int fd = drmOpen("radeon", NULL);
	assert(fd >= 0);

	// expose all planes including primary and cursor planes
	drmSetClientCap(fd, DRM_CLIENT_CAP_UNIVERSAL_PLANES, 1);

	drmModeResPtr res = drmModeGetResources(fd);
	assert (res);

	int i;
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
















