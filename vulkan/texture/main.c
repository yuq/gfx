#include <stdio.h>
#include <assert.h>
#include <stdlib.h>
#include <string.h>

#include <unistd.h>
#include <fcntl.h>

#include <png.h>

#include <vulkan/vulkan.h>

#define TARGET_W 512
#define TARGET_H 512

static int writeImage(char* filename, int width, int height, int stride,
		      void *buffer, char* title)
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

void main(void)
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
	        uint32_t physCount = 0;
		assert(vkEnumeratePhysicalDevices(inst, &physCount, NULL) == VK_SUCCESS);

		VkPhysicalDevice *devs = calloc(sizeof(*devs), physCount);
		assert(vkEnumeratePhysicalDevices(inst, &physCount, devs) == VK_SUCCESS);

		int i;
		for (i = 0; i < physCount; i++) {
			VkPhysicalDeviceProperties deviceProperties;
			vkGetPhysicalDeviceProperties(devs[i], &deviceProperties);
			VkPhysicalDeviceFeatures deviceFeatures;
			vkGetPhysicalDeviceFeatures(devs[i], &deviceFeatures);

			if (deviceProperties.deviceType == VK_PHYSICAL_DEVICE_TYPE_INTEGRATED_GPU ||
			    deviceProperties.deviceType == VK_PHYSICAL_DEVICE_TYPE_DISCRETE_GPU)
				break;
		}
		assert(i < physCount);
		phys = devs[i];
		free(devs);
	}

	VkPhysicalDeviceMemoryProperties memoryProperties = {};
	vkGetPhysicalDeviceMemoryProperties(phys, &memoryProperties);

	int LocalMemoryTypeIndex = -1;
	for (int i = 0; i < memoryProperties.memoryTypeCount; i++) {
		if (memoryProperties.memoryTypes[i].propertyFlags &
		    VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT) {
			LocalMemoryTypeIndex = i;
			break;
		}
	}
	assert(LocalMemoryTypeIndex >= 0);

	int HostVisMemoryTypeIndex = -1;
	for (int i = 0; i < memoryProperties.memoryTypeCount; i++) {
		if (memoryProperties.memoryTypes[i].propertyFlags &
		    VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT) {
			HostVisMemoryTypeIndex = i;
			break;
		}
	}
	assert(HostVisMemoryTypeIndex >= 0);

	unsigned queueFamilyIndex = 0;
	{
		uint32_t count = 0;
		vkGetPhysicalDeviceQueueFamilyProperties(phys, &count, NULL);

		VkQueueFamilyProperties *properties = calloc(count, sizeof(*properties));
		vkGetPhysicalDeviceQueueFamilyProperties(phys, &count, properties);

		for (int i = 0; i < count; i++) {
			if (properties[i].queueFlags & VK_QUEUE_GRAPHICS_BIT) {
				queueFamilyIndex = i;
				printf("queue family index = %u\n", queueFamilyIndex);
				break;
			}
		}
	}

	VkDevice device;
	{
		const float zero = 0.0f;
		VkDeviceQueueCreateInfo queueInfo = {
			.sType = VK_STRUCTURE_TYPE_DEVICE_QUEUE_CREATE_INFO,
			.queueFamilyIndex = queueFamilyIndex,
			.queueCount = 1,
			.pQueuePriorities = &zero,
		};
		VkDeviceCreateInfo info = {
			.sType = VK_STRUCTURE_TYPE_DEVICE_CREATE_INFO,
			.queueCreateInfoCount = 1,
			.pQueueCreateInfos = &queueInfo,
		};
		VkResult res = vkCreateDevice(phys, &info, NULL, &device);
		assert(res == VK_SUCCESS);
	}

	VkQueue queue;
	vkGetDeviceQueue(device, 0, 0, &queue);

	VkCommandPool commandPool;
	{
		VkCommandPoolCreateInfo info = {
			.sType = VK_STRUCTURE_TYPE_COMMAND_POOL_CREATE_INFO,
			.flags = VK_COMMAND_POOL_CREATE_RESET_COMMAND_BUFFER_BIT,
			.queueFamilyIndex = queueFamilyIndex,
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

	VkImage imageIn;
	{
		VkImageCreateInfo info = {
			.sType = VK_STRUCTURE_TYPE_IMAGE_CREATE_INFO,
			.imageType = VK_IMAGE_TYPE_2D,
			.format = VK_FORMAT_R8G8B8A8_UNORM,
			.extent = {TARGET_W / 2, TARGET_H / 2, 1},
			.mipLevels = 1,
			.arrayLayers = 1,
			.samples = VK_SAMPLE_COUNT_1_BIT,
			.tiling = VK_IMAGE_TILING_LINEAR,
			.usage = VK_IMAGE_USAGE_SAMPLED_BIT,
			.sharingMode = VK_SHARING_MODE_EXCLUSIVE,
			.initialLayout = VK_IMAGE_LAYOUT_UNDEFINED,
		};
		assert(vkCreateImage(device, &info, NULL, &imageIn) == VK_SUCCESS);
	}
	VkDeviceMemory imageInMemory;
	{		
		VkMemoryRequirements requirements;
		vkGetImageMemoryRequirements(device, imageIn, &requirements);

		VkMemoryAllocateInfo info = {
			.sType = VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_INFO,
			.allocationSize = requirements.size,
			.memoryTypeIndex = HostVisMemoryTypeIndex,
		};
		assert(vkAllocateMemory(device, &info, NULL, &imageInMemory) == VK_SUCCESS);
		assert(vkBindImageMemory(device, imageIn, imageInMemory, 0) == VK_SUCCESS);

		void* data;
		assert(vkMapMemory(device, imageInMemory, 0, VK_WHOLE_SIZE, 0, &data) == VK_SUCCESS);
		uint32_t *pixel = data;
		for (int i = 0; i < TARGET_H / 2; i++) {
			for (int j = 0; j < TARGET_W / 2; j++) {
				pixel[i * TARGET_W / 2 + j] = j <= i ? 0xff0000ff : 0;
			}
		}

		vkUnmapMemory(device, imageInMemory);
	}
	VkImageView imageInView;
	{
		VkImageViewCreateInfo info = {
			.sType = VK_STRUCTURE_TYPE_IMAGE_VIEW_CREATE_INFO,
			.image = imageIn,
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
			.usage = VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT,
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
			.memoryTypeIndex = HostVisMemoryTypeIndex,
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

	VkRenderPass renderPass;
	{
		VkAttachmentDescription color = {
			.format = VK_FORMAT_R8G8B8A8_UNORM,
			.samples = VK_SAMPLE_COUNT_1_BIT,
			.loadOp = VK_ATTACHMENT_LOAD_OP_CLEAR,
			.storeOp = VK_ATTACHMENT_STORE_OP_STORE,
			.initialLayout = VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL,
			.finalLayout = VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL,
		};
		VkAttachmentReference colorRef = {
			.attachment = 0,
			.layout = VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL,
		};
		VkSubpassDescription render = {
			.colorAttachmentCount = 1,
			.pColorAttachments = &colorRef,
		};
		VkRenderPassCreateInfo info = {
			.sType = VK_STRUCTURE_TYPE_RENDER_PASS_CREATE_INFO,
			.attachmentCount = 1,
			.pAttachments = &color,
			.subpassCount = 1,
			.pSubpasses = &render,
		};
		assert(vkCreateRenderPass(device, &info, NULL, &renderPass) == VK_SUCCESS);
	}

	VkFramebuffer framebuffer;
	{
		VkFramebufferCreateInfo info = {
			.sType = VK_STRUCTURE_TYPE_FRAMEBUFFER_CREATE_INFO,
			.renderPass = renderPass,
			.attachmentCount = 1,
			.pAttachments = &imageOutView,
			.width = TARGET_W,
			.height = TARGET_H,
			.layers = 1,
		};
		assert(vkCreateFramebuffer(device, &info, NULL, &framebuffer) == VK_SUCCESS);
	}

	float attr_in[] = {
		/* pos       tex */
		-0.5, -0.5,  0, 0,
		-0.5,  0.5,  0, 1,
		 0.5,  0.5,  1, 1,
		-0.5, -0.5,  0, 0,
		 0.5, -0.5,  1, 0,
		 0.5,  0.5,  1, 1,
	};

	VkBuffer buffer;
	{
		VkBufferCreateInfo info = {
			.sType = VK_STRUCTURE_TYPE_BUFFER_CREATE_INFO,
			.size = sizeof(attr_in),
			.usage = VK_BUFFER_USAGE_VERTEX_BUFFER_BIT,
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
			.memoryTypeIndex = HostVisMemoryTypeIndex,
		};
		assert(vkAllocateMemory(device, &info, NULL, &bufferMemory) == VK_SUCCESS);
		assert(vkBindBufferMemory(device, buffer, bufferMemory, 0) == VK_SUCCESS);

		void* data;
		assert(vkMapMemory(device, bufferMemory, 0, VK_WHOLE_SIZE, 0, &data) == VK_SUCCESS);
		memcpy(data, attr_in, sizeof(attr_in));
		vkUnmapMemory(device, bufferMemory);
	}

	VkShaderModule vs = createShaderModule(device, "vert.spv");
	VkShaderModule fs = createShaderModule(device, "frag.spv");

	VkSampler sampler;
	{
		VkSamplerCreateInfo info = {
			.sType = VK_STRUCTURE_TYPE_SAMPLER_CREATE_INFO,
			.minFilter = VK_FILTER_NEAREST,
			.magFilter = VK_FILTER_NEAREST,
			.addressModeU = VK_SAMPLER_ADDRESS_MODE_CLAMP_TO_EDGE,
			.addressModeV = VK_SAMPLER_ADDRESS_MODE_CLAMP_TO_EDGE,
		};
		assert(vkCreateSampler(device, &info, NULL, &sampler) == VK_SUCCESS);
	}

	VkDescriptorSetLayout descriptorSetLayout;
	{
		VkDescriptorSetLayoutBinding binding = {
			.binding = 0,
			.descriptorType = VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER,
			.descriptorCount = 1,
			.stageFlags = VK_SHADER_STAGE_FRAGMENT_BIT,
		};

		VkDescriptorSetLayoutCreateInfo info = {
			.sType = VK_STRUCTURE_TYPE_DESCRIPTOR_SET_LAYOUT_CREATE_INFO,
			.bindingCount = 1,
			.pBindings = &binding,
		};

		assert(vkCreateDescriptorSetLayout(device, &info, NULL, &descriptorSetLayout) == VK_SUCCESS);
	}

	VkDescriptorPool descriptorPool;
	{
		VkDescriptorPoolSize size = {
			.type = VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER,
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
		VkDescriptorImageInfo info = {
			.imageLayout = VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
			.imageView = imageInView,
			.sampler = sampler,
		};

		VkWriteDescriptorSet write = {
			.sType = VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET,
			.dstSet = descriptorSet,
			.dstBinding = 0,
			.descriptorCount = 1,
			.descriptorType = VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER,
			.pImageInfo = &info,
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
		VkVertexInputBindingDescription binding = {
			.binding = 0,
			.stride = 4 * sizeof(float),
		};

		VkVertexInputAttributeDescription attributes[2] = {
			[0] = {
				.binding = 0,
				.location = 0,
				.format = VK_FORMAT_R32G32_SFLOAT,
				.offset = 0,
			},
			[1] = {
				.binding = 0,
				.location = 1,
				.format = VK_FORMAT_R32G32_SFLOAT,
				.offset = 2 * sizeof(float),
			},
		};

		VkPipelineVertexInputStateCreateInfo vertexInputInfo = {
			.sType = VK_STRUCTURE_TYPE_PIPELINE_VERTEX_INPUT_STATE_CREATE_INFO,
			.vertexBindingDescriptionCount = 1,
			.pVertexBindingDescriptions = &binding,
			.vertexAttributeDescriptionCount = 2,
			.pVertexAttributeDescriptions = attributes,
		};

		VkPipelineInputAssemblyStateCreateInfo inputAssemblyInfo = {
			.sType = VK_STRUCTURE_TYPE_PIPELINE_INPUT_ASSEMBLY_STATE_CREATE_INFO,
			.topology = VK_PRIMITIVE_TOPOLOGY_TRIANGLE_LIST,
		};

		VkViewport viewport = {
			.width = TARGET_W,
			.height = TARGET_H,
			.maxDepth = 1.0f,
		};

		VkRect2D scissor = {
			{0, 0}, {TARGET_W, TARGET_H}
		};

		VkPipelineViewportStateCreateInfo viewportInfo = {
			.sType = VK_STRUCTURE_TYPE_PIPELINE_VIEWPORT_STATE_CREATE_INFO,
			.viewportCount = 1,
			.pViewports = &viewport,
			.scissorCount = 1,
			.pScissors = &scissor,
		};

		VkPipelineRasterizationStateCreateInfo rasterizationInfo = {
			.sType = VK_STRUCTURE_TYPE_PIPELINE_RASTERIZATION_STATE_CREATE_INFO,
			.lineWidth = 1.0f,
		};

		VkPipelineMultisampleStateCreateInfo multisampleInfo = {
			.sType = VK_STRUCTURE_TYPE_PIPELINE_MULTISAMPLE_STATE_CREATE_INFO,
			.rasterizationSamples = VK_SAMPLE_COUNT_1_BIT,
		};

		VkPipelineColorBlendAttachmentState blend = {
			.colorWriteMask =
			VK_COLOR_COMPONENT_R_BIT |
			VK_COLOR_COMPONENT_G_BIT |
			VK_COLOR_COMPONENT_B_BIT |
			VK_COLOR_COMPONENT_A_BIT,
		};
		VkPipelineColorBlendStateCreateInfo colorBlendInfo = {
			.sType = VK_STRUCTURE_TYPE_PIPELINE_COLOR_BLEND_STATE_CREATE_INFO,
			.attachmentCount = 1,
			.pAttachments = &blend,
		};

		VkPipelineShaderStageCreateInfo stages[2] = {
			[0] = {
				.sType = VK_STRUCTURE_TYPE_PIPELINE_SHADER_STAGE_CREATE_INFO,
				.stage = VK_SHADER_STAGE_VERTEX_BIT,
				.module = vs,
				.pName = "main",
			},
			[1] = {
				.sType = VK_STRUCTURE_TYPE_PIPELINE_SHADER_STAGE_CREATE_INFO,
				.stage = VK_SHADER_STAGE_FRAGMENT_BIT,
				.module = fs,
				.pName = "main",
			},
		};

		VkGraphicsPipelineCreateInfo info = {
			.sType = VK_STRUCTURE_TYPE_GRAPHICS_PIPELINE_CREATE_INFO,
			.stageCount = 2,
			.pStages = stages,
			.pVertexInputState = &vertexInputInfo,
			.pInputAssemblyState = &inputAssemblyInfo,
			.pViewportState = &viewportInfo,
			.pRasterizationState = &rasterizationInfo,
			.pMultisampleState = &multisampleInfo,
			.pColorBlendState = &colorBlendInfo,
			.layout = pipelineLayout,
			.renderPass = renderPass,
			.subpass = 0,
		};
		assert(vkCreateGraphicsPipelines(device, NULL, 1, &info, NULL, &pipeline) == VK_SUCCESS);
	}

	{
		VkCommandBufferBeginInfo info = {
			.sType = VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO,
		};
		assert(vkBeginCommandBuffer(commandBuffer, &info) == VK_SUCCESS);
	}

	{
		VkImageMemoryBarrier barrier = {
			.sType = VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER,
			.dstAccessMask = VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT,
			.oldLayout = VK_IMAGE_LAYOUT_UNDEFINED,
			.newLayout = VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL,
			.srcQueueFamilyIndex = VK_QUEUE_FAMILY_IGNORED,
			.dstQueueFamilyIndex = VK_QUEUE_FAMILY_IGNORED,
			.image = imageOut,
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

	{
		VkClearValue color = {
			.color = {
				.float32 = {0},
			},
		};
		VkRenderPassBeginInfo info = {
			.sType = VK_STRUCTURE_TYPE_RENDER_PASS_BEGIN_INFO,
			.renderPass = renderPass,
			.framebuffer = framebuffer,
			.renderArea = {{0, 0}, {TARGET_W, TARGET_H}},
			.clearValueCount = 1,
			.pClearValues = &color,
		};
		vkCmdBeginRenderPass(commandBuffer, &info, VK_SUBPASS_CONTENTS_INLINE);
	}

	vkCmdBindPipeline(commandBuffer, VK_PIPELINE_BIND_POINT_GRAPHICS, pipeline);
	vkCmdBindDescriptorSets(commandBuffer, VK_PIPELINE_BIND_POINT_GRAPHICS, pipelineLayout, 0, 1, &descriptorSet, 0, NULL);

	{
		VkDeviceSize offset = 0;
		vkCmdBindVertexBuffers(commandBuffer, 0, 1, &buffer, &offset);
	}

	vkCmdDraw(commandBuffer, 6, 1, 0, 0);

	vkCmdEndRenderPass(commandBuffer);

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

		assert(!writeImage("output.png", TARGET_W, TARGET_H, TARGET_W * 4,
				   data, "hello"));

		vkUnmapMemory(device, imageOutMemory);
	}
}
