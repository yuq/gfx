#!makefile

NATIVE_WINDOW_SYSTEM := X11

DEFS := -D_X_WINDOW_SYSTEM_
LIBS := -lEGL -lGLESv2 -lX11

test: main.c render.c
	gcc -g $(DEFS) $^ $(LIBS) -o $@

clean:
	rm -rf test

