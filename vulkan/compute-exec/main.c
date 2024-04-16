#include <stdio.h>
#include <assert.h>
#include <stdlib.h>
#include <string.h>

#include <vulkan/vulkan.h>

static VkShaderModule createShaderModule(VkDevice device, const char *name)
{
	FILE *f;
	int size;
	void *code;

	assert((f = fopen(name, "r")) != NULL);

	// get file size
	fseek(f, 0, SEEK_END);
	size = ftell(f);
	fseek(f, 0, SEEK_SET);

	assert((code = malloc(size)) != NULL);
	assert(fread(code, 1, size, f) == size);
	fclose(f);

	VkShaderModuleCreateInfo info = {
		.sType = VK_STRUCTURE_TYPE_SHADER_MODULE_CREATE_INFO,
		.codeSize = size,
		.pCode = code,
	};
	VkShaderModule shader;
        assert(vkCreateShaderModule(device, &info, NULL, &shader) == VK_SUCCESS);

	free(code);

	return shader;
}

int main(void)
{
	VkInstance inst;
	{
		VkInstanceCreateInfo info = {
			.sType = VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO,
		};
		assert(vkCreateInstance(&info, NULL, &inst) == VK_SUCCESS);
	}

	VkPhysicalDevice phys;
	{
		uint32_t physCount;
		assert(vkEnumeratePhysicalDevices(inst, &physCount, NULL) == VK_SUCCESS);

		VkPhysicalDevice *devs = calloc(sizeof(*devs), physCount);
		assert(vkEnumeratePhysicalDevices(inst, &physCount, devs) == VK_SUCCESS);

		for (int i = 0; i < physCount; i++) {
			VkPhysicalDeviceProperties deviceProperties;
			vkGetPhysicalDeviceProperties(devs[i], &deviceProperties);
			VkPhysicalDeviceFeatures deviceFeatures;
			vkGetPhysicalDeviceFeatures(devs[i], &deviceFeatures);

			if (deviceProperties.deviceType == VK_PHYSICAL_DEVICE_TYPE_INTEGRATED_GPU ||
			    deviceProperties.deviceType == VK_PHYSICAL_DEVICE_TYPE_DISCRETE_GPU) {
				phys = devs[i];
				break;
			}
		}

		free(devs);
	}

	VkPhysicalDeviceMemoryProperties memoryProperties = {};
	vkGetPhysicalDeviceMemoryProperties(phys, &memoryProperties);

	int hostVisibleMemIndex = -1;
	for (int i = 0; i < memoryProperties.memoryTypeCount; i++) {
		if (memoryProperties.memoryTypes[i].propertyFlags &
		    VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT) {
			hostVisibleMemIndex = i;
			break;
		}
	}
	assert(hostVisibleMemIndex >= 0);

	int localMemIndex = -1;
	for (int i = 0; i < memoryProperties.memoryTypeCount; i++) {
		if (memoryProperties.memoryTypes[i].propertyFlags &
		    VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT) {
			localMemIndex = i;
			break;
		}
	}
	assert(localMemIndex >= 0);

	VkDevice device;
	{
		const float zero = 0.0f;
		VkDeviceQueueCreateInfo queueInfo = {
			.sType = VK_STRUCTURE_TYPE_DEVICE_QUEUE_CREATE_INFO,
			.queueFamilyIndex = 0,
			.queueCount = 1,
			.pQueuePriorities = &zero,
		};
		VkDeviceCreateInfo info = {
			.sType = VK_STRUCTURE_TYPE_DEVICE_CREATE_INFO,
			.queueCreateInfoCount = 1,
			.pQueueCreateInfos = &queueInfo,
		};
		assert(vkCreateDevice(phys, &info, NULL, &device) == VK_SUCCESS);
	}

	VkQueue queue;
	vkGetDeviceQueue(device, 0, 0, &queue);

	VkCommandPool commandPool;
	{
		VkCommandPoolCreateInfo info = {
			.sType = VK_STRUCTURE_TYPE_COMMAND_POOL_CREATE_INFO,
			.flags = VK_COMMAND_POOL_CREATE_RESET_COMMAND_BUFFER_BIT,
			.queueFamilyIndex = 0,
		};
		assert(vkCreateCommandPool(device, &info, NULL, &commandPool) == VK_SUCCESS);
	}

	VkCommandBuffer commandBuffer;
	{
		VkCommandBufferAllocateInfo info = {
			.sType = VK_STRUCTURE_TYPE_COMMAND_BUFFER_ALLOCATE_INFO,
			.commandPool = commandPool,
			.commandBufferCount = 1,
		};
		assert(vkAllocateCommandBuffers(device, &info, &commandBuffer) == VK_SUCCESS);
	}

	VkBuffer ssbo;
	{
		VkBufferCreateInfo info = {
			.sType = VK_STRUCTURE_TYPE_BUFFER_CREATE_INFO,
			.size = 4,
			.usage = VK_BUFFER_USAGE_TRANSFER_SRC_BIT |
			         VK_BUFFER_USAGE_STORAGE_BUFFER_BIT |
			         VK_BUFFER_USAGE_TRANSFER_DST_BIT,
		};

		assert(vkCreateBuffer(device, &info, NULL, &ssbo) == VK_SUCCESS);
	}

	VkDeviceMemory ssboMemory;
	{
		VkMemoryRequirements requirements;
		vkGetBufferMemoryRequirements(device, ssbo, &requirements);

		VkMemoryAllocateInfo info = {
			.sType = VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_INFO,
			.allocationSize = requirements.size,
			.memoryTypeIndex = localMemIndex,
		};

		assert(vkAllocateMemory(device, &info, NULL, &ssboMemory) == VK_SUCCESS);
		assert(vkBindBufferMemory(device, ssbo, ssboMemory, 0) == VK_SUCCESS);
	}

	VkBuffer dataBuffer;
	{
		VkBufferCreateInfo info = {
			.sType = VK_STRUCTURE_TYPE_BUFFER_CREATE_INFO,
			.size = 4,
			.usage = VK_BUFFER_USAGE_TRANSFER_SRC_BIT |
			         VK_BUFFER_USAGE_TRANSFER_DST_BIT,
		};

		assert(vkCreateBuffer(device, &info, NULL, &dataBuffer) == VK_SUCCESS);
	}

	VkDeviceMemory dataMemory;
	{
		VkMemoryRequirements requirements;
		vkGetBufferMemoryRequirements(device, dataBuffer, &requirements);

		VkMemoryAllocateInfo info = {
			.sType = VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_INFO,
			.allocationSize = requirements.size,
			.memoryTypeIndex = hostVisibleMemIndex,
		};

		assert(vkAllocateMemory(device, &info, NULL, &dataMemory) == VK_SUCCESS);
		assert(vkBindBufferMemory(device, dataBuffer, dataMemory, 0) == VK_SUCCESS);
	}

	{
		void *cpu = NULL;
		assert(vkMapMemory(device, dataMemory, 0, 4, 0, &cpu) == VK_SUCCESS);
		memset(cpu, 0, 4);
		vkUnmapMemory(device, dataMemory);
	}

	VkShaderModule cs = createShaderModule(device, "comp.spv");

	VkDescriptorSetLayout descriptorSetLayout;
	{
		VkDescriptorSetLayoutBinding bindings = {
			.binding = 0,
			.descriptorType = VK_DESCRIPTOR_TYPE_STORAGE_BUFFER,
			.descriptorCount = 1,
			.stageFlags = VK_SHADER_STAGE_COMPUTE_BIT,
		};

		VkDescriptorSetLayoutCreateInfo info = {
			.sType = VK_STRUCTURE_TYPE_DESCRIPTOR_SET_LAYOUT_CREATE_INFO,
			.bindingCount = 1,
			.pBindings = &bindings,
		};

		assert(vkCreateDescriptorSetLayout(device, &info, NULL, &descriptorSetLayout) == VK_SUCCESS);
	}

	VkDescriptorPool descriptorPool;
	{
		VkDescriptorPoolSize size = {
			.type = VK_DESCRIPTOR_TYPE_STORAGE_BUFFER,
			.descriptorCount = 1,
		};
		VkDescriptorPoolCreateInfo info = {
			.sType = VK_STRUCTURE_TYPE_DESCRIPTOR_POOL_CREATE_INFO,
			.maxSets = 1,
			.poolSizeCount = 1,
			.pPoolSizes = &size,
		};

		assert(vkCreateDescriptorPool(device, &info, NULL, &descriptorPool) == VK_SUCCESS);
	}

	VkDescriptorSet descriptorSet;
	{

		VkDescriptorSetAllocateInfo info = {
			.sType = VK_STRUCTURE_TYPE_DESCRIPTOR_SET_ALLOCATE_INFO,
			.descriptorPool = descriptorPool,
			.descriptorSetCount = 1,
			.pSetLayouts = &descriptorSetLayout,
		};

		assert(vkAllocateDescriptorSets(device, &info, &descriptorSet) == VK_SUCCESS);
	}

	{
		VkDescriptorBufferInfo info = {
			.buffer = ssbo,
			.offset = 0,
			.range = 4,
		};

		VkWriteDescriptorSet write = {
			.sType = VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET,
			.dstSet = descriptorSet,
			.dstBinding = 0,
			.descriptorCount = 1,
			.descriptorType = VK_DESCRIPTOR_TYPE_STORAGE_BUFFER,
			.pBufferInfo = &info,
		};

		vkUpdateDescriptorSets(device, 1, &write, 0, NULL);
	}

	VkPipelineLayout pipelineLayout;
	{
		VkPipelineLayoutCreateInfo info = {
			.sType = VK_STRUCTURE_TYPE_PIPELINE_LAYOUT_CREATE_INFO,
			.setLayoutCount = 1,
			.pSetLayouts = &descriptorSetLayout,
		};
		assert(vkCreatePipelineLayout(device, &info, NULL, &pipelineLayout) == VK_SUCCESS);
	}

	VkPipeline pipeline;
	{
		VkPipelineShaderStageCreateInfo stage = {
			.sType = VK_STRUCTURE_TYPE_PIPELINE_SHADER_STAGE_CREATE_INFO,
			.stage = VK_SHADER_STAGE_COMPUTE_BIT,
			.module = cs,
			.pName = "main",
		};

		VkComputePipelineCreateInfo info = {
			.sType = VK_STRUCTURE_TYPE_COMPUTE_PIPELINE_CREATE_INFO,
			.stage = stage,
			.layout = pipelineLayout,
		};
		assert(vkCreateComputePipelines(device, NULL, 1, &info, NULL, &pipeline) == VK_SUCCESS);
	}

	{
		VkCommandBufferBeginInfo info = {
			.sType = VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO,
			.flags = VK_COMMAND_BUFFER_USAGE_ONE_TIME_SUBMIT_BIT,
		};
		assert(vkBeginCommandBuffer(commandBuffer, &info) == VK_SUCCESS);
	}

	{
		VkBufferCopy region = {
		        .srcOffset = 0,
			.dstOffset = 0,
			.size = 4,
		};

		vkCmdCopyBuffer(commandBuffer, dataBuffer, ssbo, 1, &region);
	}

	{
		VkBufferMemoryBarrier barrier = {
			.sType = VK_STRUCTURE_TYPE_BUFFER_MEMORY_BARRIER,
			.dstAccessMask = VK_ACCESS_SHADER_READ_BIT,
			.srcQueueFamilyIndex = VK_QUEUE_FAMILY_IGNORED,
			.dstQueueFamilyIndex = VK_QUEUE_FAMILY_IGNORED,
			.buffer = ssbo,
			.offset = 0,
			.size = 4,
		};
		vkCmdPipelineBarrier(commandBuffer, VK_PIPELINE_STAGE_ALL_COMMANDS_BIT,
				     VK_PIPELINE_STAGE_ALL_COMMANDS_BIT, 0, 0, NULL,
				     1, &barrier, 0, NULL);
	}

	vkCmdBindPipeline(commandBuffer, VK_PIPELINE_BIND_POINT_COMPUTE, pipeline);
	vkCmdBindDescriptorSets(commandBuffer, VK_PIPELINE_BIND_POINT_COMPUTE, pipelineLayout, 0, 1, &descriptorSet, 0, NULL);

	vkCmdDispatch(commandBuffer, 1, 1, 1);

	{
		VkBufferMemoryBarrier barrier = {
			.sType = VK_STRUCTURE_TYPE_BUFFER_MEMORY_BARRIER,
			.srcAccessMask = VK_ACCESS_SHADER_WRITE_BIT,
			.srcQueueFamilyIndex = VK_QUEUE_FAMILY_IGNORED,
			.dstQueueFamilyIndex = VK_QUEUE_FAMILY_IGNORED,
			.buffer = ssbo,
			.offset = 0,
			.size = 4,
		};
		vkCmdPipelineBarrier(commandBuffer, VK_PIPELINE_STAGE_ALL_COMMANDS_BIT,
				     VK_PIPELINE_STAGE_ALL_COMMANDS_BIT, 0, 0, NULL,
				     1, &barrier, 0, NULL);
	}

	{
		VkBufferCopy region = {
		        .srcOffset = 0,
			.dstOffset = 0,
			.size = 4,
		};

		vkCmdCopyBuffer(commandBuffer, ssbo, dataBuffer, 1, &region);
	}

	assert(vkEndCommandBuffer(commandBuffer) == VK_SUCCESS);

	VkFence fence;
	{
		VkFenceCreateInfo info = {
			info.sType = VK_STRUCTURE_TYPE_FENCE_CREATE_INFO,
		};
		assert(vkCreateFence(device, &info, NULL, &fence) == VK_SUCCESS);
	}

	{
		VkSubmitInfo info = {
			.sType = VK_STRUCTURE_TYPE_SUBMIT_INFO,
			.commandBufferCount = 1,
			.pCommandBuffers = &commandBuffer,
		};
		assert(vkQueueSubmit(queue, 1, &info, fence) == VK_SUCCESS);
	}

	assert(vkWaitForFences(device, 1, &fence, 1, 1000000000ull) == VK_SUCCESS);

	{
		void* data;
		assert(vkMapMemory(device, dataMemory, 0, VK_WHOLE_SIZE, 0, &data) == VK_SUCCESS);
		printf("result: %d\n", *(uint32_t *)data);
		vkUnmapMemory(device, dataMemory);
	}

	return 0;
}
