#!makefile

test.out: main.c comp.spv
	gcc -std=c99 -g -o $@ main.c -lvulkan -lpng

comp.spv: shader.comp
	glslangValidator -V $< -o $@
