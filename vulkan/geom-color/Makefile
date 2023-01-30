#!makefile

test.out: main.c vert.spv geom.spv frag.spv
	gcc -std=c99 -g -o $@ main.c -lvulkan -lpng

vert.spv: shader.vert
	glslangValidator -V $< -o $@

geom.spv: shader.geom
	glslangValidator -V $< -o $@

frag.spv: shader.frag
	glslangValidator -V $< -o $@
