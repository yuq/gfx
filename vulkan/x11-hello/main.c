#include <stdio.h>
#include <assert.h>
#include <stdlib.h>
#include <string.h>
#include <limits.h>
#include <unistd.h>

#define VK_USE_PLATFORM_XLIB_KHR
#include <vulkan/vulkan.h>
#include <vulkan/vk_platform.h>

#include <X11/Xlib.h>
#include <X11/Xatom.h>

#define USE_FULLSCREEN 0

int TARGET_W = 256;
int TARGET_H = 256;

Display *x11_display;
Window x11_window;

static void create_native_window(void)
{
	Display *display;
	assert((display = XOpenDisplay(NULL)) != NULL);

	int screen = DefaultScreen(display);
	Window root = DefaultRootWindow(display);

#if USE_FULLSCREEN
	XWindowAttributes attr;
	XGetWindowAttributes(display, root, &attr);
	TARGET_W = attr.width;
	TARGET_H = attr.height;
#endif

	Window window = XCreateWindow(display, root, 0, 0, TARGET_W, TARGET_H, 0,
				      DefaultDepth(display, screen), InputOutput,
				      DefaultVisual(display, screen), 
				      0, NULL);

#if USE_FULLSCREEN
	Atom wm_state = XInternAtom(display, "_NET_WM_STATE", 1);
	Atom wm_fullscreen = XInternAtom(display, "_NET_WM_STATE_FULLSCREEN", 1);

	XChangeProperty(display, window, wm_state, XA_ATOM, 32,
			PropModeReplace, (unsigned char *)&wm_fullscreen, 1);
#endif

	XMapWindow(display, window);
	XFlush(display);

	x11_display = display;
	x11_window = window;
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
	create_native_window();

	VkInstance inst;
	{
		VkInstanceCreateInfo info = {
			.sType = VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO,
			.ppEnabledExtensionNames = (const char *[]) {
				VK_KHR_SURFACE_EXTENSION_NAME,
				VK_KHR_XLIB_SURFACE_EXTENSION_NAME,
			},
			.enabledExtensionCount = 2,
		};
		assert(vkCreateInstance(&info, NULL, &inst) == VK_SUCCESS);
	}

	VkSurfaceKHR surface;
	{
		VkXlibSurfaceCreateInfoKHR info = {
			.sType = VK_STRUCTURE_TYPE_XLIB_SURFACE_CREATE_INFO_KHR,
			.dpy = x11_display,
			.window = x11_window,
		};
		assert(vkCreateXlibSurfaceKHR(inst, &info, NULL, &surface) == VK_SUCCESS);
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

	uint32_t MemoryTypeIndex;
	{
		int i;
		for (i = 0; i < memoryProperties.memoryTypeCount; i++) {
			if (memoryProperties.memoryTypes[i].propertyFlags &
			    VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT)
				break;
		}
		assert(i < memoryProperties.memoryTypeCount);
		MemoryTypeIndex = i;
	}

	uint32_t QueueFamilyIndex;
	{
		uint32_t num_queue_family = 0;
		vkGetPhysicalDeviceQueueFamilyProperties(phys, &num_queue_family, NULL);

		VkQueueFamilyProperties *props = calloc(num_queue_family, sizeof(props[0]));
		vkGetPhysicalDeviceQueueFamilyProperties(phys, &num_queue_family, props);

		int i;
	        for (i = 0; i < num_queue_family; i++) {
			VkBool32 supported;
			vkGetPhysicalDeviceSurfaceSupportKHR(phys, i, surface, &supported);
			if (supported && (props[i].queueFlags & VK_QUEUE_GRAPHICS_BIT))
				break;
		}

		assert(i < num_queue_family);
		QueueFamilyIndex = i;
		free(props);
	}

	VkSurfaceCapabilitiesKHR surface_cap;
	vkGetPhysicalDeviceSurfaceCapabilitiesKHR(phys, surface, &surface_cap);

	VkSurfaceFormatKHR surface_format;
	{
		uint32_t num_format = 0;
		vkGetPhysicalDeviceSurfaceFormatsKHR(phys, surface, &num_format, NULL);

		VkSurfaceFormatKHR *formats = calloc(num_format, sizeof(formats[0]));
		vkGetPhysicalDeviceSurfaceFormatsKHR(phys, surface, &num_format, formats);

		int i;
		for (i = 0; i < num_format; i++) {
			if (formats[i].format == VK_FORMAT_B8G8R8A8_SRGB &&
			    formats[i].colorSpace == VK_COLOR_SPACE_SRGB_NONLINEAR_KHR)
				break;
		}
		assert(i < num_format);
		surface_format = formats[i];
		free(formats);
	}

	VkPresentModeKHR present_mode;
	{
		uint32_t num_present_mode = 0;
		vkGetPhysicalDeviceSurfacePresentModesKHR(phys, surface, &num_present_mode, NULL);

		VkPresentModeKHR *modes = calloc(num_present_mode, sizeof(modes[0]));
		vkGetPhysicalDeviceSurfacePresentModesKHR(phys, surface, &num_present_mode, modes);

		int i;
		for (i = 0; i < num_present_mode; i++) {
			if (modes[i] == VK_PRESENT_MODE_FIFO_KHR)
				break;
		}
		assert(i < num_present_mode);
		present_mode = modes[i];
		free(modes);
	}

	VkDevice device;
	{
		const float zero = 0.0f;
		VkDeviceQueueCreateInfo queueInfo = {
			.sType = VK_STRUCTURE_TYPE_DEVICE_QUEUE_CREATE_INFO,
			.queueFamilyIndex = QueueFamilyIndex,
			.queueCount = 1,
			.pQueuePriorities = &zero,
		};
		VkDeviceCreateInfo info = {
			.sType = VK_STRUCTURE_TYPE_DEVICE_CREATE_INFO,
			.queueCreateInfoCount = 1,
			.pQueueCreateInfos = &queueInfo,
			.ppEnabledExtensionNames = (const char *[]) {
				VK_KHR_SWAPCHAIN_EXTENSION_NAME,
			},
			.enabledExtensionCount = 1,
			
		};
		assert(vkCreateDevice(phys, &info, NULL, &device) == VK_SUCCESS);
	}

	VkExtent2D swap_extent;
	{
		if (surface_cap.currentExtent.width != UINT_MAX)
			swap_extent = surface_cap.currentExtent;
		else {
			assert(surface_cap.minImageExtent.width <= TARGET_W);
			assert(surface_cap.maxImageExtent.width >= TARGET_W);
			assert(surface_cap.minImageExtent.height <= TARGET_H);
			assert(surface_cap.maxImageExtent.height >= TARGET_H);
			swap_extent.width = TARGET_W;
			swap_extent.height = TARGET_H;
		}
	}

	VkSwapchainKHR swap_chain;
	{
		VkSwapchainCreateInfoKHR info = {
			.sType = VK_STRUCTURE_TYPE_SWAPCHAIN_CREATE_INFO_KHR,
			.surface = surface,
			.minImageCount = surface_cap.minImageCount,
			.imageFormat = surface_format.format,
			.imageColorSpace = surface_format.colorSpace,
			.imageExtent = swap_extent,
			.imageArrayLayers = 1,
			.imageUsage = VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT,
			.imageSharingMode = VK_SHARING_MODE_EXCLUSIVE,
			.preTransform = surface_cap.currentTransform,
			.compositeAlpha = VK_COMPOSITE_ALPHA_OPAQUE_BIT_KHR,
			.presentMode = present_mode,
			.clipped = VK_TRUE,	
		};
		assert(vkCreateSwapchainKHR(device, &info, NULL, &swap_chain) == VK_SUCCESS);
	}

	uint32_t num_image = 0;
	vkGetSwapchainImagesKHR(device, swap_chain, &num_image, NULL);
	VkImage *images = calloc(num_image, sizeof(images[0]));
	vkGetSwapchainImagesKHR(device, swap_chain, &num_image, images);

	VkImageView *image_views = calloc(num_image, sizeof(image_views[0]));
	for (int i = 0; i < num_image; i++) {
		VkImageViewCreateInfo info = {
			.sType = VK_STRUCTURE_TYPE_IMAGE_VIEW_CREATE_INFO,
			.image = images[i],
			.viewType = VK_IMAGE_VIEW_TYPE_2D,
			.format = surface_format.format,
			.subresourceRange = {
				.aspectMask = VK_IMAGE_ASPECT_COLOR_BIT,
				.baseMipLevel = 0,
				.levelCount = 1,
				.baseArrayLayer = 0,
				.layerCount = 1,
			},
		};
		assert(vkCreateImageView(device, &info, NULL, image_views + i) == VK_SUCCESS);
	}

	VkQueue queue;
	vkGetDeviceQueue(device, QueueFamilyIndex, 0, &queue);

	VkCommandPool commandPool;
	{
		VkCommandPoolCreateInfo info = {
			.sType = VK_STRUCTURE_TYPE_COMMAND_POOL_CREATE_INFO,
			.flags = VK_COMMAND_POOL_CREATE_RESET_COMMAND_BUFFER_BIT,
			.queueFamilyIndex = QueueFamilyIndex,
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

	VkRenderPass renderPass;
	{
		VkAttachmentDescription color = {
			.format = surface_format.format,
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

	VkFramebuffer *framebuffers = calloc(num_image, sizeof(framebuffers[0]));
	for (int i = 0; i < num_image; i++) {
		VkFramebufferCreateInfo info = {
			.sType = VK_STRUCTURE_TYPE_FRAMEBUFFER_CREATE_INFO,
			.renderPass = renderPass,
			.attachmentCount = 1,
			.pAttachments = image_views + i,
			.width = TARGET_W,
			.height = TARGET_H,
			.layers = 1,
		};
		assert(vkCreateFramebuffer(device, &info, NULL, framebuffers + i) == VK_SUCCESS);
	}

	VkSemaphore imageAvailableSemaphore;
	VkSemaphore renderFinishedSemaphore;
	{
		VkSemaphoreCreateInfo info = {
			.sType = VK_STRUCTURE_TYPE_SEMAPHORE_CREATE_INFO,
		};
		assert(vkCreateSemaphore(device, &info, NULL, &imageAvailableSemaphore) == VK_SUCCESS);
		assert(vkCreateSemaphore(device, &info, NULL, &renderFinishedSemaphore) == VK_SUCCESS);
	}

	VkFence inFlightFence;
	{
		VkFenceCreateInfo info = {
			.sType = VK_STRUCTURE_TYPE_FENCE_CREATE_INFO,
			.flags = VK_FENCE_CREATE_SIGNALED_BIT,
		};
		assert(vkCreateFence(device, &info, NULL, &inFlightFence) == VK_SUCCESS);
	}

	float vertex[] = {
		-1, -1,
		-1,  1,
		 1,  1,
		 1, -1,
	};
	VkBuffer buffer;
	{
		VkBufferCreateInfo info = {
			.sType = VK_STRUCTURE_TYPE_BUFFER_CREATE_INFO,
			.size = sizeof(vertex),
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
			.memoryTypeIndex = MemoryTypeIndex,
		};
		assert(vkAllocateMemory(device, &info, NULL, &bufferMemory) == VK_SUCCESS);
		assert(vkBindBufferMemory(device, buffer, bufferMemory, 0) == VK_SUCCESS);

		void* data;
		assert(vkMapMemory(device, bufferMemory, 0, VK_WHOLE_SIZE, 0, &data) == VK_SUCCESS);
		memcpy(data, vertex, sizeof(vertex));
		vkUnmapMemory(device, bufferMemory);
	}

	VkShaderModule vs = createShaderModule(device, "vert.spv");
	VkShaderModule fs = createShaderModule(device, "frag.spv");

	VkPipelineLayout pipelineLayout;
	{
		VkPipelineLayoutCreateInfo info = {
			.sType = VK_STRUCTURE_TYPE_PIPELINE_LAYOUT_CREATE_INFO,
			.setLayoutCount = 0,
			.pushConstantRangeCount = 0,
		};
		assert(vkCreatePipelineLayout(device, &info, NULL, &pipelineLayout) == VK_SUCCESS);
	}

	VkPipeline pipeline;
	{
		VkVertexInputBindingDescription binding = {
			.binding = 0,
			.stride = 2 * sizeof(float),
		};

		VkVertexInputAttributeDescription attribute = {
			.location = 0,
			.binding = binding.binding,
			.format = VK_FORMAT_R32G32_SFLOAT,
			.offset = 0,
		};

		VkPipelineVertexInputStateCreateInfo vertexInputInfo = {
			.sType = VK_STRUCTURE_TYPE_PIPELINE_VERTEX_INPUT_STATE_CREATE_INFO,
			.vertexBindingDescriptionCount = 1,
			.pVertexBindingDescriptions = &binding,
			.vertexAttributeDescriptionCount = 1,
			.pVertexAttributeDescriptions = &attribute,
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

	for (int i = 0; i < 60; i++) {
		vkWaitForFences(device, 1, &inFlightFence, VK_TRUE, UINT64_MAX);
		vkResetFences(device, 1, &inFlightFence);

		uint32_t imageIndex;
		vkAcquireNextImageKHR(device, swap_chain, UINT64_MAX, imageAvailableSemaphore, VK_NULL_HANDLE, &imageIndex);

		vkResetCommandBuffer(commandBuffer, 0);

		{
			VkCommandBufferBeginInfo info = {
				.sType = VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO,
			};
			assert(vkBeginCommandBuffer(commandBuffer, &info) == VK_SUCCESS);
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
				.framebuffer = framebuffers[imageIndex],
				.renderArea = {{0, 0}, {TARGET_W, TARGET_H}},
				.clearValueCount = 1,
				.pClearValues = &color,
			};
			vkCmdBeginRenderPass(commandBuffer, &info, VK_SUBPASS_CONTENTS_INLINE);
		}

		vkCmdBindPipeline(commandBuffer, VK_PIPELINE_BIND_POINT_GRAPHICS, pipeline);

		{
			VkDeviceSize offset = (i & 1) * 8;
			vkCmdBindVertexBuffers(commandBuffer, 0, 1, &buffer, &offset);
		}

		vkCmdDraw(commandBuffer, 3, 1, 0, 0);

		vkCmdEndRenderPass(commandBuffer);

		assert(vkEndCommandBuffer(commandBuffer) == VK_SUCCESS);

		{
			VkSubmitInfo info = {
				.sType = VK_STRUCTURE_TYPE_SUBMIT_INFO,
				.commandBufferCount = 1,
				.pCommandBuffers = &commandBuffer,
				.waitSemaphoreCount = 1,
				.pWaitSemaphores = (VkSemaphore []) {
					imageAvailableSemaphore,
				},
				.pWaitDstStageMask = (VkPipelineStageFlags []) {
					VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT,
				},
				.signalSemaphoreCount = 1,
				.pSignalSemaphores = (VkSemaphore []) {
					renderFinishedSemaphore,
				},
			};
			assert(vkQueueSubmit(queue, 1, &info, inFlightFence) == VK_SUCCESS);
		}

		{
			VkPresentInfoKHR info = {
				.sType = VK_STRUCTURE_TYPE_PRESENT_INFO_KHR,
				.waitSemaphoreCount = 1,
				.pWaitSemaphores = (VkSemaphore []) {
					renderFinishedSemaphore,
				},
				.swapchainCount = 1,
				.pSwapchains = (VkSwapchainKHR []) {
					swap_chain,
				},
				.pImageIndices = &imageIndex,
			};
			vkQueuePresentKHR(queue, &info);
		}

		sleep(1);
	}

	return 0;
}
