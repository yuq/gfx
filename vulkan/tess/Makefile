#!makefile

test.out: main.c vert.spv tesc.spv tese.spv frag.spv
	gcc -std=c99 -g -o $@ main.c -lvulkan -lpng

vert.spv: shader.vert
	glslangValidator -V $< -o $@

tesc.spv: shader.tesc
	glslangValidator -V $< -o $@

tese.spv: shader.tese
	glslangValidator -V $< -o $@

frag.spv: shader.frag
	glslangValidator -V $< -o $@
