#!makefile

CFLAGS += -g -D_GNU_SOURCE $(shell PKG_CONFIG_PATH=/opt/amdgpu-pro/lib/x86_64-linux-gnu/pkgconfig pkg-config --cflags libdrm libdrm_amdgpu)
LDFLAGS += $(shell PKG_CONFIG_PATH=/opt/amdgpu-pro/lib/x86_64-linux-gnu/pkgconfig pkg-config --libs libdrm libdrm_amdgpu)

test: main.c
	$(CC) $(CFLAGS) -o $@ $^ $(LDFLAGS)
