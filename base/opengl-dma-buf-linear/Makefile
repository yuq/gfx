#!makefile

CFLAGS += -g $(shell pkg-config --cflags libdrm epoxy gbm)
LDFLAGS += $(shell pkg-config --libs epoxy gbm)

test.out: main.c
	gcc $(CFLAGS) -o $@ $^ $(LDFLAGS)

