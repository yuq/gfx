#include <stdio.h>
#include <assert.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <sys/socket.h>
#include <unistd.h>
#include <fcntl.h>
#include <xf86drm.h>
#include <xf86drmMode.h>

ssize_t
sock_fd_write(int sock, void *buf, ssize_t buflen, int fd)
{
    ssize_t     size;
    struct msghdr   msg;
    struct iovec    iov;
    union {
        struct cmsghdr  cmsghdr;
        char        control[CMSG_SPACE(sizeof (int))];
    } cmsgu;
    struct cmsghdr  *cmsg;

    iov.iov_base = buf;
    iov.iov_len = buflen;

    msg.msg_name = NULL;
    msg.msg_namelen = 0;
    msg.msg_iov = &iov;
    msg.msg_iovlen = 1;

    if (fd != -1) {
        msg.msg_control = cmsgu.control;
        msg.msg_controllen = sizeof(cmsgu.control);

        cmsg = CMSG_FIRSTHDR(&msg);
        cmsg->cmsg_len = CMSG_LEN(sizeof (int));
        cmsg->cmsg_level = SOL_SOCKET;
        cmsg->cmsg_type = SCM_RIGHTS;

        printf ("passing fd %d\n", fd);
        *((int *) CMSG_DATA(cmsg)) = fd;
    } else {
        msg.msg_control = NULL;
        msg.msg_controllen = 0;
        printf ("not passing fd\n");
    }

    size = sendmsg(sock, &msg, 0);

    if (size < 0)
        perror ("sendmsg");
    return size;
}

ssize_t
sock_fd_read(int sock, void *buf, ssize_t bufsize, int *fd)
{
    ssize_t     size;

    if (fd) {
        struct msghdr   msg;
        struct iovec    iov;
        union {
            struct cmsghdr  cmsghdr;
            char        control[CMSG_SPACE(sizeof (int))];
        } cmsgu;
        struct cmsghdr  *cmsg;

        iov.iov_base = buf;
        iov.iov_len = bufsize;

        msg.msg_name = NULL;
        msg.msg_namelen = 0;
        msg.msg_iov = &iov;
        msg.msg_iovlen = 1;
        msg.msg_control = cmsgu.control;
        msg.msg_controllen = sizeof(cmsgu.control);
        size = recvmsg (sock, &msg, 0);
        if (size < 0) {
            perror ("recvmsg");
            exit(1);
        }
        cmsg = CMSG_FIRSTHDR(&msg);
        if (cmsg && cmsg->cmsg_len == CMSG_LEN(sizeof(int))) {
            if (cmsg->cmsg_level != SOL_SOCKET) {
                fprintf (stderr, "invalid cmsg_level %d\n",
                     cmsg->cmsg_level);
                exit(1);
            }
            if (cmsg->cmsg_type != SCM_RIGHTS) {
                fprintf (stderr, "invalid cmsg_type %d\n",
                     cmsg->cmsg_type);
                exit(1);
            }

            *fd = *((int *) CMSG_DATA(cmsg));
            printf ("received fd %d\n", *fd);
        } else
            *fd = -1;
    } else {
        size = read (sock, buf, bufsize);
        if (size < 0) {
            perror("read");
            exit(1);
        }
    }
    return size;
}

struct buffer_info {
	uint32_t pitch;
	uint64_t size;
};

void
child(int sock)
{
	int prime_fd;
    struct buffer_info bi;
    ssize_t size;

    sleep(1);
    for (;;) {
        size = sock_fd_read(sock, &bi, sizeof(bi), &prime_fd);
        if (size <= 0)
            break;
        printf ("read %d\n", size);
        assert(prime_fd >= 0);
		break;
    }

	int fd = drmOpen("radeon", NULL);
	assert(fd >= 0);

	uint32_t handle;
	assert(!drmPrimeFDToHandle(fd, prime_fd, &handle));

	struct drm_mode_map_dumb mreq;
	memset(&mreq, 0, sizeof(mreq));
	mreq.handle = handle;
	assert(!drmIoctl(fd, DRM_IOCTL_MODE_MAP_DUMB, &mreq));

	uint32_t *map = mmap(0, bi.size, PROT_READ | PROT_WRITE, MAP_SHARED, fd, mreq.offset);
	assert(map != MAP_FAILED);
	memset(map, 0, bi.size);

	sleep(1);
	int i, j;
	for (i = 230; i < 600; i++)
		for (j = 100; j < 300; j++)
			map[i * (bi.pitch >> 2) + j] = 0x12345678;

	close(prime_fd);
	drmClose(fd);
}

void
parent(int sock)
{
	int fd = drmOpen("radeon", NULL);
	assert(fd >= 0);

	uint64_t cap;
	assert(!drmGetCap(fd, DRM_CAP_PRIME, &cap));
	assert((cap & DRM_PRIME_CAP_IMPORT) && (cap & DRM_PRIME_CAP_EXPORT));

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

	assert(!drmModeSetCrtc(fd, crtc->crtc_id, my_fb, 0, 0, &connector->connector_id, 1, &crtc->mode));

	int prime_fd;
	assert(!drmPrimeHandleToFD(fd, creq.handle, DRM_CLOEXEC, &prime_fd) && prime_fd);

	struct buffer_info bi = {
		.pitch = creq.pitch,
		.size = creq.size
	};
	ssize_t size = sock_fd_write(sock, &bi, sizeof(bi), prime_fd);
    printf ("wrote %d\n", size);

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
}

int
main(int argc, char **argv)
{
    int sv[2];
    int pid;

    if (socketpair(AF_LOCAL, SOCK_STREAM, 0, sv) < 0) {
        perror("socketpair");
        exit(1);
    }
    switch ((pid = fork())) {
    case 0:
        close(sv[0]);
        child(sv[1]);
        break;
    case -1:
        perror("fork");
        exit(1);
    default:
        close(sv[1]);
        parent(sv[0]);
        break;
    }
    return 0;
}
