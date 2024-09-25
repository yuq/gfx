#!makefile

test.out: main.c comp.spv
	gcc -g -o $@ main.c -lvulkan -lpng -lgbm -lepoxy

comp.spv: shader.comp
	glslangValidator -V $< -o $@
