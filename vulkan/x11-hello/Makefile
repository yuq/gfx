#!makefile

test.out: main.c vert.spv frag.spv
	gcc -std=c99 -g -o $@ main.c -lvulkan -lX11

vert.spv: shader.vert
	glslangValidator -V $< -o $@

frag.spv: shader.frag
	glslangValidator -V $< -o $@
