#!makefile

test.out: main.c task.spv mesh.spv frag.spv
	gcc -std=c99 -g -o $@ main.c -lvulkan -lpng

task.spv: shader.task
	glslangValidator --target-env spirv1.4 -V $< -o $@

mesh.spv: shader.mesh
	glslangValidator --target-env spirv1.4 -V $< -o $@

frag.spv: shader.frag
	glslangValidator --target-env spirv1.4 -V $< -o $@
