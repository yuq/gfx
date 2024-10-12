#!makefile

test.out: main.c vert.spv frag.spv
	gcc -g -o $@ main.c -lvulkan -lpng -lgbm -lepoxy

vert.spv: shader.vert
	glslangValidator -V $< -o $@

frag.spv: shader.frag
	glslangValidator -V $< -o $@
