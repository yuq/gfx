#!makefile

test.out: vert.spv frag.spv main.c
	gcc -std=c99 -g -o $@ main.c -lgbm -lepoxy -lpng

vert.spv: shader.vert
	glslangValidator -G $< -o $@

frag.spv: shader.frag
	glslangValidator -G $< -o $@
