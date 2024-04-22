#!makefile

test.out: main.c one.spv two.spv
	gcc -std=c99 -g -o $@ main.c -lvulkan

one.spv: one.comp
	glslangValidator -V $< -o $@

two.spv: two.comp
	glslangValidator -V $< -o $@
