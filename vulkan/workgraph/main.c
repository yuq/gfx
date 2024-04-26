#include <stdio.h>
#include <assert.h>
#include <stdlib.h>
#include <string.h>

#define VK_ENABLE_BETA_EXTENSIONS
#include <vulkan/vulkan.h>

// Entrypoints of VK_AMDX_shader_enqueue
static PFN_vkCreateExecutionGraphPipelinesAMDX _vkCreateExecutionGraphPipelinesAMDX;
static PFN_vkGetExecutionGraphPipelineScratchSizeAMDX _vkGetExecutionGraphPipelineScratchSizeAMDX;
static PFN_vkGetExecutionGraphPipelineNodeIndexAMDX _vkGetExecutionGraphPipelineNodeIndexAMDX;
static PFN_vkCmdInitializeGraphScratchMemoryAMDX _vkCmdInitializeGraphScratchMemoryAMDX;
static PFN_vkCmdDispatchGraphAMDX _vkCmdDispatchGraphAMDX;
static PFN_vkCmdDispatchGraphIndirectAMDX _vkCmdDispatchGraphIndirectAMDX;
static PFN_vkCmdDispatchGraphIndirectCountAMDX _vkCmdDispatchGraphIndirectCountAMDX;

static void load_extension_function_pointers(VkDevice device)
{
    _vkCreateExecutionGraphPipelinesAMDX        = (PFN_vkCreateExecutionGraphPipelinesAMDX)       vkGetDeviceProcAddr(device, "vkCreateExecutionGraphPipelinesAMDX");
    _vkGetExecutionGraphPipelineScratchSizeAMDX = (PFN_vkGetExecutionGraphPipelineScratchSizeAMDX)vkGetDeviceProcAddr(device, "vkGetExecutionGraphPipelineScratchSizeAMDX");
    _vkGetExecutionGraphPipelineNodeIndexAMDX   = (PFN_vkGetExecutionGraphPipelineNodeIndexAMDX)  vkGetDeviceProcAddr(device, "vkGetExecutionGraphPipelineNodeIndexAMDX");
    _vkCmdInitializeGraphScratchMemoryAMDX      = (PFN_vkCmdInitializeGraphScratchMemoryAMDX)     vkGetDeviceProcAddr(device, "vkCmdInitializeGraphScratchMemoryAMDX");
    _vkCmdDispatchGraphAMDX                     = (PFN_vkCmdDispatchGraphAMDX)                    vkGetDeviceProcAddr(device, "vkCmdDispatchGraphAMDX");
    _vkCmdDispatchGraphIndirectAMDX             = (PFN_vkCmdDispatchGraphIndirectAMDX)            vkGetDeviceProcAddr(device, "vkCmdDispatchGraphIndirectAMDX");
    _vkCmdDispatchGraphIndirectCountAMDX        = (PFN_vkCmdDispatchGraphIndirectCountAMDX)       vkGetDeviceProcAddr(device, "vkCmdDispatchGraphIndirectCountAMDX");
}

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
	        VkApplicationInfo app = {
			.sType = VK_STRUCTURE_TYPE_APPLICATION_INFO,
			.apiVersion = VK_MAKE_VERSION(1, 2, 0),
		};
		VkInstanceCreateInfo info = {
			.sType = VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO,
			.pApplicationInfo = &app,
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
			VkPhysicalDeviceShaderEnqueueFeaturesAMDX enqueue_feature = {
				.sType =  VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SHADER_ENQUEUE_FEATURES_AMDX,
			};
			VkPhysicalDeviceFeatures2 device_features = {
				.sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_FEATURES_2,
				.pNext = &enqueue_feature,
			};
			vkGetPhysicalDeviceFeatures2(devs[i], &device_features);

			if (enqueue_feature.shaderEnqueue) {
				VkPhysicalDeviceShaderEnqueuePropertiesAMDX enqueue_property = {
					.sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SHADER_ENQUEUE_PROPERTIES_AMDX,
				};
				VkPhysicalDeviceProperties2 device_properties = {
					.sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_PROPERTIES_2,
					.pNext = &enqueue_property,
				};
				vkGetPhysicalDeviceProperties2(devs[i], &device_properties);
				printf("found device %s\n", device_properties.properties.deviceName);
				printf("  maxExecutionGraphDepth=%d\n", enqueue_property.maxExecutionGraphDepth);
				printf("  maxExecutionGraphShaderOutputNodes=%d\n", enqueue_property.maxExecutionGraphShaderOutputNodes);
				printf("  maxExecutionGraphShaderPayloadSize=%d\n", enqueue_property.maxExecutionGraphShaderPayloadSize);
				printf("  maxExecutionGraphShaderPayloadCount=%d\n", enqueue_property.maxExecutionGraphShaderPayloadCount);
				printf("  executionGraphDispatchAddressAlignment=%d\n", enqueue_property.executionGraphDispatchAddressAlignment);
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
		VkPhysicalDeviceBufferDeviceAddressFeatures address_feature = {
			.sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_BUFFER_DEVICE_ADDRESS_FEATURES,
			.bufferDeviceAddress = VK_TRUE,
		};
		VkPhysicalDeviceShaderEnqueueFeaturesAMDX enqueue_feature = {
			.sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SHADER_ENQUEUE_FEATURES_AMDX,
			.pNext = &address_feature,
			.shaderEnqueue = VK_TRUE,
		};
		const char *extensions[] = {
			VK_AMDX_SHADER_ENQUEUE_EXTENSION_NAME,
		};
		VkDeviceCreateInfo info = {
			.sType = VK_STRUCTURE_TYPE_DEVICE_CREATE_INFO,
			.pNext = &enqueue_feature,
			.queueCreateInfoCount = 1,
			.pQueueCreateInfos = &queueInfo,
			.enabledExtensionCount = 1,
			.ppEnabledExtensionNames = extensions,
		};
		assert(vkCreateDevice(phys, &info, NULL, &device) == VK_SUCCESS);
	}

	load_extension_function_pointers(device);

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
	unsigned ssboSize = 0x100000;
	{
		VkBufferCreateInfo info = {
			.sType = VK_STRUCTURE_TYPE_BUFFER_CREATE_INFO,
			.size = ssboSize,
			.usage = VK_BUFFER_USAGE_STORAGE_BUFFER_BIT,
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
			.memoryTypeIndex = hostVisibleMemIndex,
		};

		assert(vkAllocateMemory(device, &info, NULL, &ssboMemory) == VK_SUCCESS);
		assert(vkBindBufferMemory(device, ssbo, ssboMemory, 0) == VK_SUCCESS);
	}

	void *ssboCpu = NULL;
	{
		assert(vkMapMemory(device, ssboMemory, 0, ssboSize, 0, &ssboCpu) == VK_SUCCESS);
		memset(ssboCpu, 0, ssboSize);
	}

	VkShaderModule one = createShaderModule(device, "one.spv");
	VkShaderModule two = createShaderModule(device, "two.spv");

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
			.range = ssboSize,
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
		VkPipelineShaderStageNodeCreateInfoAMDX one_node = {
			.sType = VK_STRUCTURE_TYPE_PIPELINE_SHADER_STAGE_NODE_CREATE_INFO_AMDX,
			.pName = "one",
			.index = 0,
		};
		VkPipelineShaderStageNodeCreateInfoAMDX two_node = {
			.sType = VK_STRUCTURE_TYPE_PIPELINE_SHADER_STAGE_NODE_CREATE_INFO_AMDX,
			.pName = "two",
			.index = 1,
		};
		VkPipelineShaderStageCreateInfo stages[] = {
			[0] = {
				.sType = VK_STRUCTURE_TYPE_PIPELINE_SHADER_STAGE_CREATE_INFO,
				.pNext = &one_node,
				.stage = VK_SHADER_STAGE_COMPUTE_BIT,
				.module = one,
				.pName = "main",
			},
			[1] = {
				.sType = VK_STRUCTURE_TYPE_PIPELINE_SHADER_STAGE_CREATE_INFO,
				.pNext = &two_node,
				.stage = VK_SHADER_STAGE_COMPUTE_BIT,
				.module = two,
				.pName = "main",
			},
		};
		VkExecutionGraphPipelineCreateInfoAMDX info = {
			.sType = VK_STRUCTURE_TYPE_EXECUTION_GRAPH_PIPELINE_CREATE_INFO_AMDX,
			.stageCount = 2,
			.pStages = stages,
			.layout = pipelineLayout,
			.basePipelineHandle = VK_NULL_HANDLE,
			.basePipelineIndex = -1,
		};
		assert(_vkCreateExecutionGraphPipelinesAMDX(device, NULL, 1, &info, NULL, &pipeline) == VK_SUCCESS);
	}

		unsigned scratchSize;
	{
		VkExecutionGraphPipelineScratchSizeAMDX info = {
			.sType = VK_STRUCTURE_TYPE_EXECUTION_GRAPH_PIPELINE_SCRATCH_SIZE_AMDX,
		};
		assert(_vkGetExecutionGraphPipelineScratchSizeAMDX(device, pipeline, &info) == VK_SUCCESS);
		scratchSize = info.size;
	}

	VkBuffer scratch;
	{
		VkBufferCreateInfo info = {
			.sType = VK_STRUCTURE_TYPE_BUFFER_CREATE_INFO,
			.size = scratchSize,
			.usage = VK_BUFFER_USAGE_EXECUTION_GRAPH_SCRATCH_BIT_AMDX |
			         VK_BUFFER_USAGE_SHADER_DEVICE_ADDRESS_BIT,
		};

		assert(vkCreateBuffer(device, &info, NULL, &scratch) == VK_SUCCESS);
	}

	VkDeviceMemory scratchMemory;
	{
		VkMemoryRequirements requirements;
		vkGetBufferMemoryRequirements(device, scratch, &requirements);

		VkMemoryAllocateInfo info = {
			.sType = VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_INFO,
			.allocationSize = requirements.size,
			.memoryTypeIndex = localMemIndex,
		};

		assert(vkAllocateMemory(device, &info, NULL, &scratchMemory) == VK_SUCCESS);
		assert(vkBindBufferMemory(device, scratch, scratchMemory, 0) == VK_SUCCESS);
	}

	VkDeviceAddress scratchAddr;
	{
		VkBufferDeviceAddressInfo info = {
			.sType  = VK_STRUCTURE_TYPE_BUFFER_DEVICE_ADDRESS_INFO,
			.buffer = scratch,
		};

		scratchAddr = vkGetBufferDeviceAddress(device, &info);
	}

	{
		VkCommandBufferBeginInfo info = {
			.sType = VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO,
			.flags = VK_COMMAND_BUFFER_USAGE_ONE_TIME_SUBMIT_BIT,
		};
		assert(vkBeginCommandBuffer(commandBuffer, &info) == VK_SUCCESS);
	}

	vkCmdBindPipeline(commandBuffer, VK_PIPELINE_BIND_POINT_EXECUTION_GRAPH_AMDX, pipeline);
	vkCmdBindDescriptorSets(commandBuffer, VK_PIPELINE_BIND_POINT_COMPUTE, pipelineLayout, 0, 1, &descriptorSet, 0, NULL);
	_vkCmdInitializeGraphScratchMemoryAMDX(commandBuffer, scratchAddr);

	{
		VkBufferMemoryBarrier barrier = {
			.sType = VK_STRUCTURE_TYPE_BUFFER_MEMORY_BARRIER,
			.srcAccessMask = VK_ACCESS_SHADER_READ_BIT|VK_ACCESS_SHADER_WRITE_BIT,
			.dstAccessMask = VK_ACCESS_SHADER_READ_BIT|VK_ACCESS_SHADER_WRITE_BIT,
			.buffer = scratch,
			.size = VK_WHOLE_SIZE,
		};
		vkCmdPipelineBarrier(commandBuffer, VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT,
				     VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, 0, 0, NULL,
				     1, &barrier, 0, NULL);
	}

	uint32_t nodeIndex;
	{
		VkPipelineShaderStageNodeCreateInfoAMDX info = {
			.pName = "one",
			.index = 0,
		};
		assert(_vkGetExecutionGraphPipelineNodeIndexAMDX(device, pipeline, &info, &nodeIndex) == VK_SUCCESS);
	}

	{
		unsigned payload_data = 2;
		VkDispatchGraphInfoAMDX payload = {
			.nodeIndex = nodeIndex,
			.payloadCount = 1,
			.payloads.hostAddress = &payload_data,
			.payloadStride = 4,
		};
		VkDispatchGraphCountInfoAMDX info = {
			.count = 1,
			.infos.hostAddress = &payload,
			.stride = sizeof(payload),
		};
		_vkCmdDispatchGraphAMDX(commandBuffer, scratchAddr, &info);
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

	assert(vkWaitForFences(device, 1, &fence, 1, 1000000000000ull) == VK_SUCCESS);

	{
		unsigned *data = ssboCpu;
		printf("result: %d %d %d %d\n", data[0], data[1], data[2], data[3]);
	}

	return 0;
}
