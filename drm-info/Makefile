#!makefile

CFLAGS += -g $(shell pkg-config --cflags libdrm)
LDFLAGS += $(shell pkg-config --libs libdrm)

test: main.c
	$(CC) $(CFLAGS) -o $@ $^ $(LDFLAGS)
