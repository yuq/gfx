// This example program creates an EGL surface from a GBM surface.
//
// If the macro EGL_MESA_platform_gbm is defined, then the program
// creates the surfaces using the methods defined in this specification.
// Otherwise, it uses the methods defined by the EGL 1.4 specification.
//
// Compile with `cc -std=c99 example.c -lgbm -lEGL`.

#include <stdlib.h>
#include <string.h>

#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>

#include <EGL/egl.h>
#include <gbm.h>

//#define EGL_MESA_platform_gbm

struct my_display {
	struct gbm_device *gbm;
	EGLDisplay egl;
};

struct my_config {
	struct my_display dpy;
	EGLConfig egl;
};

struct my_window {
	struct my_config config;
	struct gbm_surface *gbm;
	EGLSurface egl;
};

static void
check_extensions(void)
{
#ifdef EGL_MESA_platform_gbm
	const char *client_extensions = eglQueryString(EGL_NO_DISPLAY, EGL_EXTENSIONS);

	if (!client_extensions) {
		// EGL_EXT_client_extensions is unsupported.
		abort();
	}
	if (!strstr(client_extensions, "EGL_MESA_platform_gbm")) {
		abort();
	}
#endif
}

static struct my_display
get_display(void)
{
	struct my_display dpy;

	int fd = open("/dev/dri/card0", O_RDWR);
	if (fd < 0) {
		abort();
	}

	dpy.gbm = gbm_create_device(fd);
	if (!dpy.gbm) {
		abort();
	}


#ifdef EGL_MESA_platform_gbm
	dpy.egl = eglGetPlatformDisplayEXT(EGL_PLATFORM_GBM_MESA, dpy.gbm, NULL);
#else
	dpy.egl = eglGetDisplay(dpy.gbm);
#endif

	if (dpy.egl == EGL_NO_DISPLAY) {
		abort();
	}

	EGLint major, minor;
	if (!eglInitialize(dpy.egl, &major, &minor)) {
		abort();
	}

	return dpy;
}

static struct my_config
get_config(struct my_display dpy)
{
	struct my_config config = {
		.dpy = dpy,
	};

	EGLint egl_config_attribs[] = {
		EGL_BUFFER_SIZE,        32,
		EGL_DEPTH_SIZE,         EGL_DONT_CARE,
		EGL_STENCIL_SIZE,       EGL_DONT_CARE,
		EGL_RENDERABLE_TYPE,    EGL_OPENGL_ES2_BIT,
		EGL_SURFACE_TYPE,       EGL_WINDOW_BIT,
		EGL_NONE,
	};

	EGLint num_configs;
	if (!eglGetConfigs(dpy.egl, NULL, 0, &num_configs)) {
		abort();
	}

	EGLConfig *configs = malloc(num_configs * sizeof(EGLConfig));
	if (!eglChooseConfig(dpy.egl, egl_config_attribs,
						 configs, num_configs, &num_configs)) {
		abort();
	}
	if (num_configs == 0) {
		abort();
	}

	// Find a config whose native visual ID is the desired GBM format.
	for (int i = 0; i < num_configs; ++i) {
		EGLint gbm_format;

		if (!eglGetConfigAttrib(dpy.egl, configs[i],
								EGL_NATIVE_VISUAL_ID, &gbm_format)) {
			abort();
		}

		if (gbm_format == GBM_FORMAT_XRGB8888) {
			config.egl = configs[i];
			return config;
		}
	}

	// Failed to find a config with matching GBM format.
	abort();
}

static struct my_window
get_window(struct my_config config)
{
	struct my_window window = {
		.config = config,
	};

	window.gbm = gbm_surface_create(config.dpy.gbm,
									256, 256,
									GBM_FORMAT_XRGB8888,
									GBM_BO_USE_RENDERING);
	if (!window.gbm) {
		abort();
	}

#ifdef EGL_MESA_platform_gbm
	window.egl = eglCreatePlatformWindowSurfaceEXT(config.dpy.egl,
												   config.egl,
												   window.gbm,
												   NULL);
#else
	window.egl = eglCreateWindowSurface(config.dpy.egl,
										config.egl,
										window.gbm,
										NULL);
#endif

	if (window.egl == EGL_NO_SURFACE) {
		abort();
	}

	return window;
}

int
main(void)
{
	check_extensions();

	struct my_display dpy = get_display();
	struct my_config config = get_config(dpy);
	struct my_window window = get_window(config);

	return 0;
}
