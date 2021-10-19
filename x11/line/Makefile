#!makefile

NATIVE_WINDOW_SYSTEM := X11

DEFS :=
LIBS := -lEGL -lGLESv2

ifeq ($(NATIVE_WINDOW_SYSTEM),X11)
DEFS += -D_X_WINDOW_SYSTEM_
LIBS += -lX11
else
DEFS += -D_MALI_FRAMEBUFFER_
endif

test: main.c render.c
	gcc -g $(DEFS) $^ $(LIBS) -o $@

clean:
	rm -rf test

