#!makefile

test.out: main.c rgen.spv rchit.spv rmiss.spv
	gcc -std=c99 -g -o $@ main.c -lvulkan -lpng

rgen.spv: shader.rgen
	glslangValidator --target-env spirv1.4 -V $< -o $@

rchit.spv: shader.rchit
	glslangValidator --target-env spirv1.4 -V $< -o $@

rmiss.spv: shader.rmiss
	glslangValidator --target-env spirv1.4 -V $< -o $@
