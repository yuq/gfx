#include <stdio.h>
#include <assert.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>

#include <png.h>

#include <vulkan/vulkan.h>

#define TARGET_W 512
#define TARGET_H 512

static int writeImage(char* filename, int width, int height, int stride, void *buffer, char* title)
{
	int code = 0;
	FILE *fp = NULL;
	png_structp png_ptr = NULL;
	png_infop info_ptr = NULL;

	// Open file for writing (binary mode)
	fp = fopen(filename, "wb");
	if (fp == NULL) {
		fprintf(stderr, "Could not open file %s for writing\n", filename);
		code = 1;
		goto finalise;
	}

	// Initialize write structure
	png_ptr = png_create_write_struct(PNG_LIBPNG_VER_STRING, NULL, NULL, NULL);
	if (png_ptr == NULL) {
		fprintf(stderr, "Could not allocate write struct\n");
		code = 1;
		goto finalise;
	}

	// Initialize info structure
	info_ptr = png_create_info_struct(png_ptr);
	if (info_ptr == NULL) {
		fprintf(stderr, "Could not allocate info struct\n");
		code = 1;
		goto finalise;
	}

	// Setup Exception handling
	if (setjmp(png_jmpbuf(png_ptr))) {
		fprintf(stderr, "Error during png creation\n");
		code = 1;
		goto finalise;
	}

	png_init_io(png_ptr, fp);

	// Write header (8 bit colour depth)
	png_set_IHDR(png_ptr, info_ptr, width, height,
		     8, PNG_COLOR_TYPE_RGB_ALPHA, PNG_INTERLACE_NONE,
		     PNG_COMPRESSION_TYPE_DEFAULT, PNG_FILTER_TYPE_DEFAULT);

	// Set title
	if (title != NULL) {
		png_text title_text;
		title_text.compression = PNG_TEXT_COMPRESSION_NONE;
		title_text.key = "Title";
		title_text.text = title;
		png_set_text(png_ptr, info_ptr, &title_text, 1);
	}

	png_write_info(png_ptr, info_ptr);

	// Write image data
	int i;
	for (i = 0; i < height; i++)
		png_write_row(png_ptr, (png_bytep)buffer + i * stride);

	// End write
	png_write_end(png_ptr, NULL);

finalise:
	if (fp != NULL) fclose(fp);
	if (info_ptr != NULL) png_free_data(png_ptr, info_ptr, PNG_FREE_ALL, -1);
	if (png_ptr != NULL) png_destroy_write_struct(&png_ptr, (png_infopp)NULL);

	return code;
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
				assert(deviceProperties.sparseProperties.residencyStandard2DBlockShape &&
				       deviceProperties.sparseProperties.residencyNonResidentStrict);
				assert(deviceFeatures.sparseBinding &&
				       deviceFeatures.sparseResidencyImage2D);
				phys = devs[i];
				break;
			}
		}

		free(devs);
	}

	VkPhysicalDeviceMemoryProperties memoryProperties = {};
	vkGetPhysicalDeviceMemoryProperties(phys, &memoryProperties);

	uint32_t hostVisibleMemIndex;
	for (int i = 0; i < memoryProperties.memoryHeapCount; i++) {
		if (memoryProperties.memoryTypes[i].propertyFlags &
		    VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT) {
			hostVisibleMemIndex = i;
			break;
		}
	}

	uint32_t localMemIndex;
	for (int i = 0; i < memoryProperties.memoryHeapCount; i++) {
		if (memoryProperties.memoryTypes[i].propertyFlags &
		    VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT) {
			localMemIndex = i;
			break;
		}
	}

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

	VkBuffer buffer;
	unsigned bufferSize = TARGET_W * TARGET_H;
	{
		VkBufferCreateInfo info = {
			.sType = VK_STRUCTURE_TYPE_BUFFER_CREATE_INFO,
			.size = bufferSize,
			.usage = VK_BUFFER_USAGE_TRANSFER_SRC_BIT,
		};

		assert(vkCreateBuffer(device, &info, NULL, &buffer) == VK_SUCCESS);
	}

	VkDeviceMemory bufferMemory;
	{
		VkMemoryRequirements requirements;
		vkGetBufferMemoryRequirements(device, buffer, &requirements);

		VkMemoryAllocateInfo info = {
			.sType = VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_INFO,
			.allocationSize = requirements.size,
			.memoryTypeIndex = hostVisibleMemIndex,
		};

		assert(vkAllocateMemory(device, &info, NULL, &bufferMemory) == VK_SUCCESS);
		assert(vkBindBufferMemory(device, buffer, bufferMemory, 0) == VK_SUCCESS);
	}

	{
		void *cpu = NULL;
		assert(vkMapMemory(device, bufferMemory, 0, bufferSize, 0, &cpu) == VK_SUCCESS);
		memset(cpu, 255, bufferSize);
		vkUnmapMemory(device, bufferMemory);
	}

	VkImage imageIn;
	{
		VkImageCreateInfo info = {
			.sType = VK_STRUCTURE_TYPE_IMAGE_CREATE_INFO,
			.imageType = VK_IMAGE_TYPE_2D,
			.format = VK_FORMAT_R8_UNORM,
			.extent = {TARGET_W, TARGET_H, 1},
			.mipLevels = 1,
			.arrayLayers = 1,
			.samples = VK_SAMPLE_COUNT_1_BIT,
			.tiling = VK_IMAGE_TILING_OPTIMAL,
			.usage = VK_IMAGE_USAGE_TRANSFER_DST_BIT | VK_IMAGE_USAGE_STORAGE_BIT,
			.initialLayout = VK_IMAGE_LAYOUT_UNDEFINED,
			.flags = VK_IMAGE_CREATE_SPARSE_BINDING_BIT | VK_IMAGE_CREATE_SPARSE_RESIDENCY_BIT,
		};
		assert(vkCreateImage(device, &info, NULL, &imageIn) == VK_SUCCESS);
	}
	VkDeviceMemory imageInMemory;
	{
		uint32_t count = 0;
		vkGetImageSparseMemoryRequirements(device, imageIn, &count, NULL);

		VkSparseImageMemoryRequirements *requirements = calloc(sizeof(*requirements), count);
		vkGetImageSparseMemoryRequirements(device, imageIn, &count, requirements);

		bool found = false;
		VkSparseImageMemoryRequirements req;
		for (int i = 0; i < count; i++) {
			if (requirements[i].formatProperties.aspectMask & VK_IMAGE_ASPECT_COLOR_BIT) {
				found = true;
				req = requirements[i];
				break;
			}
		}
		assert(found);

		VkMemoryAllocateInfo info = {
			.sType = VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_INFO,
			.allocationSize = (TARGET_W / 2) * (TARGET_H / 2),
			.memoryTypeIndex = localMemIndex,
		};
		assert(vkAllocateMemory(device, &info, NULL, &imageInMemory) == VK_SUCCESS);

		VkSparseImageMemoryBind bind = {
			.extent = {
				.width = TARGET_W / 2,
				.height = TARGET_H / 2,
				.depth = 1,
			},
			.memory = imageInMemory,
			.subresource = {
				.aspectMask = VK_IMAGE_ASPECT_COLOR_BIT,
			},
		};
		VkSparseImageMemoryBindInfo memBindInfo = {
			.image = imageIn,
			.bindCount = 1,
			.pBinds = &bind,
		};
		VkBindSparseInfo sparseBindInfo = {
			.sType = VK_STRUCTURE_TYPE_BIND_SPARSE_INFO,
			.imageBindCount = 1,
			.pImageBinds = &memBindInfo,
		};
		vkQueueBindSparse(queue, 1, &sparseBindInfo, NULL);
		vkQueueWaitIdle(queue);
	}
	VkImageView imageInView;
	{
		VkImageViewCreateInfo info = {
			.sType = VK_STRUCTURE_TYPE_IMAGE_VIEW_CREATE_INFO,
			.image = imageIn,
			.viewType = VK_IMAGE_VIEW_TYPE_2D,
			.format = VK_FORMAT_R8_UNORM,
			.subresourceRange = {
				.aspectMask = VK_IMAGE_ASPECT_COLOR_BIT,
				.baseMipLevel = 0,
				.levelCount = 1,
				.baseArrayLayer = 0,
				.layerCount = 1,
			},
		};
		assert(vkCreateImageView(device, &info, NULL, &imageInView) == VK_SUCCESS);
	}

	VkImage imageOut;
	{
		VkImageCreateInfo info = {
			.sType = VK_STRUCTURE_TYPE_IMAGE_CREATE_INFO,
			.imageType = VK_IMAGE_TYPE_2D,
			.format = VK_FORMAT_R8G8B8A8_UNORM,
			.extent = {TARGET_W, TARGET_H, 1},
			.mipLevels = 1,
			.arrayLayers = 1,
			.samples = VK_SAMPLE_COUNT_1_BIT,
			.tiling = VK_IMAGE_TILING_LINEAR,
			.usage = VK_IMAGE_USAGE_STORAGE_BIT,
			.initialLayout = VK_IMAGE_LAYOUT_UNDEFINED,
		};
		assert(vkCreateImage(device, &info, NULL, &imageOut) == VK_SUCCESS);
	}
	VkDeviceMemory imageOutMemory;
	{
		VkMemoryRequirements requirements;
		vkGetImageMemoryRequirements(device, imageOut, &requirements);

		VkMemoryAllocateInfo info = {
			.sType = VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_INFO,
			.allocationSize = requirements.size,
			.memoryTypeIndex = hostVisibleMemIndex,
		};
		assert(vkAllocateMemory(device, &info, NULL, &imageOutMemory) == VK_SUCCESS);
		assert(vkBindImageMemory(device, imageOut, imageOutMemory, 0) == VK_SUCCESS);
	}
	VkImageView imageOutView;
	{
		VkImageViewCreateInfo info = {
			.sType = VK_STRUCTURE_TYPE_IMAGE_VIEW_CREATE_INFO,
			.image = imageOut,
			.viewType = VK_IMAGE_VIEW_TYPE_2D,
			.format = VK_FORMAT_R8G8B8A8_UNORM,
			.subresourceRange = {
				.aspectMask = VK_IMAGE_ASPECT_COLOR_BIT,
				.baseMipLevel = 0,
				.levelCount = 1,
				.baseArrayLayer = 0,
				.layerCount = 1,
			},
		};
		assert(vkCreateImageView(device, &info, NULL, &imageOutView) == VK_SUCCESS);
	}

	VkShaderModule cs = createShaderModule(device, "comp.spv");

	VkDescriptorSetLayout descriptorSetLayout;
	{
		VkDescriptorSetLayoutBinding bindings[2] = {
			[0] = {
				.binding = 0,
				.descriptorType = VK_DESCRIPTOR_TYPE_STORAGE_IMAGE,
				.descriptorCount = 1,
				.stageFlags = VK_SHADER_STAGE_COMPUTE_BIT,
			},
			[1] = {
				.binding = 1,
				.descriptorType = VK_DESCRIPTOR_TYPE_STORAGE_IMAGE,
				.descriptorCount = 1,
				.stageFlags = VK_SHADER_STAGE_COMPUTE_BIT,
			},
		};

		VkDescriptorSetLayoutCreateInfo info = {
			.sType = VK_STRUCTURE_TYPE_DESCRIPTOR_SET_LAYOUT_CREATE_INFO,
			.bindingCount = 2,
			.pBindings = bindings,
		};

		assert(vkCreateDescriptorSetLayout(device, &info, NULL, &descriptorSetLayout) == VK_SUCCESS);
	}

	VkDescriptorPool descriptorPool;
	{
		VkDescriptorPoolSize size = {
			.type = VK_DESCRIPTOR_TYPE_STORAGE_IMAGE,
			.descriptorCount = 2,
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
		VkDescriptorImageInfo infos[2] = {
			[0] = {
				.imageView = imageInView,
			},
			[1] = {
				.imageView = imageOutView,
			},
		};

		VkWriteDescriptorSet write = {
			.sType = VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET,
			.dstSet = descriptorSet,
			.dstBinding = 0,
			.descriptorCount = 2,
			.descriptorType = VK_DESCRIPTOR_TYPE_STORAGE_IMAGE,
			.pImageInfo = infos,
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
		VkBufferImageCopy region = {
			.bufferRowLength = TARGET_W,
			.imageSubresource = {
				.aspectMask = VK_IMAGE_ASPECT_COLOR_BIT,
				.layerCount = 1,
			},
			.imageExtent = {
				.width = TARGET_W,
				.height = TARGET_H,
				.depth = 1,
			},
		};

		vkCmdCopyBufferToImage(commandBuffer, buffer, imageIn, VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL, 1, &region);
	}

	{
		VkImageMemoryBarrier barrier = {
			.sType = VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER,
			.dstAccessMask = VK_ACCESS_SHADER_READ_BIT,
			.oldLayout = VK_IMAGE_LAYOUT_UNDEFINED,
			.newLayout = VK_IMAGE_LAYOUT_UNDEFINED,
			.srcQueueFamilyIndex = VK_QUEUE_FAMILY_IGNORED,
			.dstQueueFamilyIndex = VK_QUEUE_FAMILY_IGNORED,
			.image = imageIn,
			.subresourceRange = {
				.aspectMask = VK_IMAGE_ASPECT_COLOR_BIT,
				.baseMipLevel = 0,
				.levelCount = 1,
				.baseArrayLayer = 0,
				.layerCount = 1,
			},
		};
		vkCmdPipelineBarrier(commandBuffer, VK_PIPELINE_STAGE_ALL_COMMANDS_BIT,
				     VK_PIPELINE_STAGE_ALL_COMMANDS_BIT, 0, 0, NULL, 0,
				     NULL, 1, &barrier);
	}

	vkCmdBindPipeline(commandBuffer, VK_PIPELINE_BIND_POINT_COMPUTE, pipeline);
	vkCmdBindDescriptorSets(commandBuffer, VK_PIPELINE_BIND_POINT_COMPUTE, pipelineLayout, 0, 1, &descriptorSet, 0, NULL);

	vkCmdDispatch(commandBuffer, TARGET_W >> 4, TARGET_H >> 4, 1);

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
		assert(vkMapMemory(device, imageOutMemory, 0, VK_WHOLE_SIZE, 0, &data) == VK_SUCCESS);

		assert(!writeImage("screenshot.png", TARGET_W, TARGET_H, TARGET_W * 4,
				   data, "hello"));

		vkUnmapMemory(device, imageOutMemory);
	}

	return 0;
}
