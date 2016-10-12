#!makefile

CFLAGS += -g -D_GNU_SOURCE $(shell pkg-config --cflags libdrm libdrm_amdgpu)
LDFLAGS += $(shell pkg-config --libs libdrm libdrm_amdgpu)

test: main.c
	$(CC) $(CFLAGS) -o $@ $^ $(LDFLAGS)
