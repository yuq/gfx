#!makefile

test.out: main.c mesh.spv frag.spv
	gcc -std=c99 -g -o $@ main.c -lvulkan -lpng

mesh.spv: shader.mesh
	glslangValidator --target-env spirv1.4 -V $< -o $@

frag.spv: shader.frag
	glslangValidator --target-env spirv1.4 -V $< -o $@
