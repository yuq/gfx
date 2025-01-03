#include <stdio.h>
#include <assert.h>
#include <stdlib.h>
#include <string.h>

#include <unistd.h>
#include <fcntl.h>

#include <png.h>

#include <gbm.h>

#include <epoxy/gl.h>
#include <epoxy/egl.h>

#include <vulkan/vulkan.h>

#include <drm/drm_fourcc.h>

//#define USE_OPTIMAL 1

#define MAX_PLANES 3
int img_fds[MAX_PLANES];
int img_strides[MAX_PLANES];
int img_offsets[MAX_PLANES];
uint64_t img_modifiers[MAX_PLANES];
int img_num_planes = 0;
int img_fourcc;

#define VK_TARGET_W 512
#define VK_TARGET_H 512
#define OGL_TARGET_W 256
#define OGL_TARGET_H 256

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

VkFormat drm_format_to_vk_format(int format)
{
	switch (format) {
	case DRM_FORMAT_ABGR8888:
		return VK_FORMAT_R8G8B8A8_UNORM;
	default:
		printf("no VkFormat for drm format %x\n", format);
		assert(0);
		return VK_FORMAT_UNDEFINED;
	}
}

void render_vulkan(void)
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
			if (properties[i].queueFlags & VK_QUEUE_COMPUTE_BIT) {
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
		const char *extensions[] = {
			"VK_KHR_external_memory",
			"VK_KHR_dedicated_allocation",
			"VK_KHR_external_memory_fd",
			"VK_KHR_get_memory_requirements2",
#ifndef USE_OPTIMAL
			"VK_EXT_image_drm_format_modifier",
#endif
		};
		VkDeviceCreateInfo info = {
			.sType = VK_STRUCTURE_TYPE_DEVICE_CREATE_INFO,
			.queueCreateInfoCount = 1,
			.pQueueCreateInfos = &queueInfo,
			.enabledExtensionCount = sizeof(extensions) / sizeof(extensions[0]),
			.ppEnabledExtensionNames = extensions,
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

	VkFormat format = drm_format_to_vk_format(img_fourcc);
	if (img_modifiers[0] != DRM_FORMAT_MOD_INVALID) {
	        VkDrmFormatModifierPropertiesListEXT mprop = {
			.sType = VK_STRUCTURE_TYPE_DRM_FORMAT_MODIFIER_PROPERTIES_LIST_EXT,
		};
		VkFormatProperties2 prop = {
			.sType = VK_STRUCTURE_TYPE_FORMAT_PROPERTIES_2,
			.pNext = &mprop,
		};
		vkGetPhysicalDeviceFormatProperties2(phys, format, &prop);

		assert(mprop.drmFormatModifierCount);
		VkDrmFormatModifierPropertiesEXT mprops[mprop.drmFormatModifierCount];
		mprop.pDrmFormatModifierProperties = mprops;
		vkGetPhysicalDeviceFormatProperties2(phys, format, &prop);

		bool found = false;
		for (int i = 0; i < mprop.drmFormatModifierCount; i++) {
			if (img_modifiers[0] == mprops[i].drmFormatModifier) {
				assert(img_num_planes == mprops[i].drmFormatModifierPlaneCount);
				found = mprops[i].drmFormatModifierTilingFeatures & VK_FORMAT_FEATURE_STORAGE_IMAGE_BIT;
				break;
			}
		}
		printf("format %x with modifier %" PRIx64, img_fourcc, img_modifiers[0]);
		if (!found) {
			printf(" not supported\n");
			return;
		} else {
			printf(" supported\n");
		}
	}

	VkImage imageIn;
	{
#ifndef USE_OPTIMAL
		VkSubresourceLayout layouts[MAX_PLANES] = {0};
		for (int i = 0; i < img_num_planes; i++) {
			layouts[i].offset = img_offsets[i];
			layouts[i].rowPitch = img_strides[i];
		}
		VkImageDrmFormatModifierExplicitCreateInfoEXT modifier = {
			.sType = VK_STRUCTURE_TYPE_IMAGE_DRM_FORMAT_MODIFIER_EXPLICIT_CREATE_INFO_EXT,
			.drmFormatModifier = img_modifiers[0],
			.drmFormatModifierPlaneCount = img_num_planes,
			.pPlaneLayouts = layouts,
		};
#endif
		VkExternalMemoryImageCreateInfo external = {
			.sType = VK_STRUCTURE_TYPE_EXTERNAL_MEMORY_IMAGE_CREATE_INFO,
#ifndef USE_OPTIMAL
			.pNext = &modifier,
#endif
			.handleTypes = VK_EXTERNAL_MEMORY_HANDLE_TYPE_DMA_BUF_BIT_EXT,
		};
		VkImageCreateInfo info = {
			.sType = VK_STRUCTURE_TYPE_IMAGE_CREATE_INFO,
			.pNext = &external,
			.imageType = VK_IMAGE_TYPE_2D,
			.format = format,
			.extent = {OGL_TARGET_W, OGL_TARGET_H, 1},
			.mipLevels = 1,
			.arrayLayers = 1,
			.samples = VK_SAMPLE_COUNT_1_BIT,
#ifndef USE_OPTIMAL 
			.tiling = VK_IMAGE_TILING_DRM_FORMAT_MODIFIER_EXT,
#endif
			.usage = VK_IMAGE_USAGE_STORAGE_BIT,
			.sharingMode = VK_SHARING_MODE_EXCLUSIVE,
			.initialLayout = VK_IMAGE_LAYOUT_GENERAL,
		};
		assert(vkCreateImage(device, &info, NULL, &imageIn) == VK_SUCCESS);
	}
	VkDeviceMemory imageInMemory;
	{
		for (int i = 1; i < img_num_planes; i++)
			assert(img_fds[i] == -1);

		PFN_vkGetMemoryFdPropertiesKHR GetMemoryFdPropertiesKHR =
			(PFN_vkGetMemoryFdPropertiesKHR)vkGetDeviceProcAddr(device, "vkGetMemoryFdPropertiesKHR");

		VkMemoryFdPropertiesKHR fd_props;
		assert(GetMemoryFdPropertiesKHR(device,
						VK_EXTERNAL_MEMORY_HANDLE_TYPE_DMA_BUF_BIT_EXT,
						img_fds[0], &fd_props) == VK_SUCCESS);
		
		VkMemoryRequirements requirements;
		vkGetImageMemoryRequirements(device, imageIn, &requirements);

		VkImportMemoryFdInfoKHR import_info = {
			.sType = VK_STRUCTURE_TYPE_IMPORT_MEMORY_FD_INFO_KHR,
			.handleType = VK_EXTERNAL_MEMORY_HANDLE_TYPE_DMA_BUF_BIT_EXT,
			.fd = img_fds[0],
		};
	        VkMemoryDedicatedAllocateInfo dedicated_info = {
			.sType = VK_STRUCTURE_TYPE_MEMORY_DEDICATED_ALLOCATE_INFO,
			.pNext = &import_info,
			.image = imageIn,
		};
		VkMemoryAllocateInfo info = {
			.sType = VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_INFO,
			.pNext = &dedicated_info,
			.allocationSize = requirements.size,
			.memoryTypeIndex = ffs(fd_props.memoryTypeBits) - 1,
		};
		assert(vkAllocateMemory(device, &info, NULL, &imageInMemory) == VK_SUCCESS);
		assert(vkBindImageMemory(device, imageIn, imageInMemory, 0) == VK_SUCCESS);
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
			.extent = {VK_TARGET_W, VK_TARGET_H, 1},
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

	vkCmdBindPipeline(commandBuffer, VK_PIPELINE_BIND_POINT_COMPUTE, pipeline);
	vkCmdBindDescriptorSets(commandBuffer, VK_PIPELINE_BIND_POINT_COMPUTE, pipelineLayout, 0, 1, &descriptorSet, 0, NULL);

	vkCmdDispatch(commandBuffer, VK_TARGET_W >> 4, VK_TARGET_H >> 4, 1);

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

		assert(!writeImage("vulkan.png", VK_TARGET_W, VK_TARGET_H, VK_TARGET_W * 4,
				   data, "hello"));

		vkUnmapMemory(device, imageOutMemory);
	}
}

EGLDisplay display;
EGLContext context;
struct gbm_device *gbm;

void RenderTargetInit(char *name)
{
	assert(epoxy_has_egl_extension(EGL_NO_DISPLAY, "EGL_MESA_platform_gbm"));

	int fd = open(name, O_RDWR);
	assert(fd >= 0);

	gbm = gbm_create_device(fd);
	assert(gbm != NULL);

	assert((display = eglGetPlatformDisplayEXT(EGL_PLATFORM_GBM_MESA, gbm, NULL)) != EGL_NO_DISPLAY);

	EGLint majorVersion;
	EGLint minorVersion;
	assert(eglInitialize(display, &majorVersion, &minorVersion) == EGL_TRUE);

	assert(eglBindAPI(EGL_OPENGL_API) == EGL_TRUE);

	assert((context = eglCreateContext(display, NULL, EGL_NO_CONTEXT, NULL)) != EGL_NO_CONTEXT);

	assert(eglMakeCurrent(display, EGL_NO_SURFACE, EGL_NO_SURFACE, context) == EGL_TRUE);
}

void CheckFrameBufferStatus(void)
{
	GLenum status;
	status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
	switch(status) {
	case GL_FRAMEBUFFER_COMPLETE:
		printf("Framebuffer complete\n");
		break;
	case GL_FRAMEBUFFER_UNSUPPORTED:
		printf("Framebuffer unsuported\n");
		break;
	case GL_FRAMEBUFFER_INCOMPLETE_ATTACHMENT:
		printf("GL_FRAMEBUFFER_INCOMPLETE_ATTACHMENT\n");
		break;
	case GL_FRAMEBUFFER_INCOMPLETE_MISSING_ATTACHMENT:
		printf("GL_FRAMEBUFFER_MISSING_ATTACHMENT\n");
		break;
	default:
		printf("Framebuffer error\n");
	}
}

GLuint LoadShader(const char *name, GLenum type)
{
	FILE *f;
	int size;
	char *buff;
	GLuint shader;
	GLint compiled;
	const GLchar *source[1];

	assert((f = fopen(name, "r")) != NULL);

	// get file size
	fseek(f, 0, SEEK_END);
	size = ftell(f);
	fseek(f, 0, SEEK_SET);

	assert((buff = malloc(size)) != NULL);
	assert(fread(buff, 1, size, f) == size);
	source[0] = buff;
	fclose(f);
	shader = glCreateShader(type);
	glShaderSource(shader, 1, source, &size);
	glCompileShader(shader);
	free(buff);
	glGetShaderiv(shader, GL_COMPILE_STATUS, &compiled);
	if (!compiled) {
		GLint infoLen = 0;
		glGetShaderiv(shader, GL_INFO_LOG_LENGTH, &infoLen);
		if (infoLen > 1) {
			char *infoLog = malloc(infoLen);
			glGetShaderInfoLog(shader, infoLen, NULL, infoLog);
			fprintf(stderr, "Error compiling shader %s:\n%s\n", name, infoLog);
			free(infoLog);
		}
		glDeleteShader(shader);
		return 0;
	}

	return shader;
}

void InitGLES(void)
{
	GLuint program;
	GLint linked;
	GLuint vertexShader;
	GLuint fragmentShader;
	assert((vertexShader = LoadShader("vert.glsl", GL_VERTEX_SHADER)) != 0);
	assert((fragmentShader = LoadShader("frag.glsl", GL_FRAGMENT_SHADER)) != 0);
	assert((program = glCreateProgram()) != 0);
	glAttachShader(program, vertexShader);
	glAttachShader(program, fragmentShader);
	glLinkProgram(program);
	glGetProgramiv(program, GL_LINK_STATUS, &linked);
	if (!linked) {
		GLint infoLen = 0;
		glGetProgramiv(program, GL_INFO_LOG_LENGTH, &infoLen);
		if (infoLen > 1) {
			char *infoLog = malloc(infoLen);
			glGetProgramInfoLog(program, infoLen, NULL, infoLog);
			fprintf(stderr, "Error linking program:\n%s\n", infoLog);
			free(infoLog);
		}
		glDeleteProgram(program);
		exit(1);
	}

	glUseProgram(program);
}

void Render(void)
{
	glClearColor(0, 0, 0, 0);
	glViewport(0, 0, OGL_TARGET_W, OGL_TARGET_H);

	assert(epoxy_has_egl_extension(display, "EGL_MESA_image_dma_buf_export"));

	GLuint fbid;
	glGenFramebuffers(1, &fbid);
	glBindFramebuffer(GL_FRAMEBUFFER, fbid);

	GLuint texid;
	glGenTextures(1, &texid);
	glBindTexture(GL_TEXTURE_2D, texid);
	glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, OGL_TARGET_W, OGL_TARGET_H, 0, GL_RGBA, GL_UNSIGNED_BYTE, NULL);
	glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, texid, 0);

	CheckFrameBufferStatus();

	GLfloat vertex[] = {
		-1, -1, 0,
		-1, 1, 0,
		1, 1, 0,
		1, -1, 0
	};
        GLuint vao;
	glGenVertexArrays(1, &vao);
	glBindVertexArray(vao);

	GLuint vbo;
	glGenBuffers(1, &vbo);
	glBindBuffer(GL_ARRAY_BUFFER, vbo);
	glBufferData(GL_ARRAY_BUFFER, sizeof(vertex), vertex, GL_STATIC_DRAW);

	glEnableVertexAttribArray(0);
	glVertexAttribPointer(0, 3, GL_FLOAT, 0, 0, 0);
	assert(glGetError() == GL_NO_ERROR);

	glClear(GL_COLOR_BUFFER_BIT);
	assert(glGetError() == GL_NO_ERROR);

	glDrawArrays(GL_TRIANGLES, 0, 3);
	assert(glGetError() == GL_NO_ERROR);

	EGLImage image = eglCreateImage(display, context, EGL_GL_TEXTURE_2D,
					(EGLClientBuffer)(intptr_t)texid, NULL);
	assert(image != EGL_NO_IMAGE);

	EGLBoolean ret = eglExportDMABUFImageQueryMESA(display, image, &img_fourcc,
						       &img_num_planes, img_modifiers);
	assert(ret == EGL_TRUE);
	assert(img_num_planes <= MAX_PLANES);

	assert(eglExportDMABUFImageMESA(display, image, img_fds, img_strides, img_offsets));

	for (int i = 0; i < img_num_planes; i++)
		printf("plane %d: fd=%d offset=%x stride=%x\n",
		       i, img_fds[i], img_offsets[i], img_strides[i]);

	GLubyte result[OGL_TARGET_W * OGL_TARGET_H * 4] = {0};
	glReadPixels(0, 0, OGL_TARGET_W, OGL_TARGET_H, GL_RGBA, GL_UNSIGNED_BYTE, result);
	assert(glGetError() == GL_NO_ERROR);

	assert(!writeImage("opengl.png", OGL_TARGET_W, OGL_TARGET_H,
			   OGL_TARGET_W * 4, result, "hello"));
}


void render_opengl(void)
{
	RenderTargetInit("/dev/dri/renderD128");
	InitGLES();
	Render();
}

void InitCompute(void)
{
	GLuint program;
	GLint linked;
	GLuint computeShader;
	assert((computeShader = LoadShader("shader.comp", GL_COMPUTE_SHADER)) != 0);
	assert((program = glCreateProgram()) != 0);
	glAttachShader(program, computeShader);
	glLinkProgram(program);
	glGetProgramiv(program, GL_LINK_STATUS, &linked);
	if (!linked) {
		GLint infoLen = 0;
		glGetProgramiv(program, GL_INFO_LOG_LENGTH, &infoLen);
		if (infoLen > 1) {
			char *infoLog = malloc(infoLen);
			glGetProgramInfoLog(program, infoLen, NULL, infoLog);
			fprintf(stderr, "Error linking program:\n%s\n", infoLog);
			free(infoLog);
		}
		glDeleteProgram(program);
		exit(1);
	}

	glUseProgram(program);
}

void Compute(void)
{
	EGLint attrib_list[6 + MAX_PLANES * 10 + 1] = {0};
	unsigned num = 0;

	attrib_list[num++] = EGL_WIDTH;
	attrib_list[num++] = OGL_TARGET_W;

	attrib_list[num++] = EGL_HEIGHT;
	attrib_list[num++] = OGL_TARGET_H;

	attrib_list[num++] = EGL_LINUX_DRM_FOURCC_EXT;
	attrib_list[num++] = img_fourcc;

	attrib_list[num++] = EGL_DMA_BUF_PLANE0_FD_EXT;
	attrib_list[num++] = img_fds[0];
	attrib_list[num++] = EGL_DMA_BUF_PLANE0_OFFSET_EXT;
	attrib_list[num++] = img_offsets[0];
	attrib_list[num++] = EGL_DMA_BUF_PLANE0_PITCH_EXT;
	attrib_list[num++] = img_strides[0];
#ifndef USE_OPTIMAL
	attrib_list[num++] = EGL_DMA_BUF_PLANE0_MODIFIER_LO_EXT;
	attrib_list[num++] = img_modifiers[0];
	attrib_list[num++] = EGL_DMA_BUF_PLANE0_MODIFIER_HI_EXT;
	attrib_list[num++] = img_modifiers[0] >> 32;
#endif

	if (img_num_planes > 1) {
		attrib_list[num++] = EGL_DMA_BUF_PLANE1_FD_EXT;
		attrib_list[num++] = img_fds[1] >= 0 ? img_fds[1] : img_fds[0];
		attrib_list[num++] = EGL_DMA_BUF_PLANE1_OFFSET_EXT;
		attrib_list[num++] = img_offsets[1];
		attrib_list[num++] = EGL_DMA_BUF_PLANE1_PITCH_EXT;
		attrib_list[num++] = img_strides[1];
#ifndef USE_OPTIMAL
		attrib_list[num++] = EGL_DMA_BUF_PLANE1_MODIFIER_LO_EXT;
		attrib_list[num++] = img_modifiers[1];
		attrib_list[num++] = EGL_DMA_BUF_PLANE1_MODIFIER_HI_EXT;
		attrib_list[num++] = img_modifiers[1] >> 32;
#endif
	}

	if (img_num_planes > 2) {
		attrib_list[num++] = EGL_DMA_BUF_PLANE2_FD_EXT;
		attrib_list[num++] = img_fds[2] >= 0 ? img_fds[2] : img_fds[0];
		attrib_list[num++] = EGL_DMA_BUF_PLANE2_OFFSET_EXT;
		attrib_list[num++] = img_offsets[2];
		attrib_list[num++] = EGL_DMA_BUF_PLANE2_PITCH_EXT;
		attrib_list[num++] = img_strides[2];
#ifndef USE_OPTIMAL
		attrib_list[num++] = EGL_DMA_BUF_PLANE2_MODIFIER_LO_EXT;
		attrib_list[num++] = img_modifiers[2];
		attrib_list[num++] = EGL_DMA_BUF_PLANE2_MODIFIER_HI_EXT;
		attrib_list[num++] = img_modifiers[2] >> 32;
#endif
	}

	attrib_list[num++] = EGL_NONE;

	EGLImage image = eglCreateImageKHR(display, EGL_NO_CONTEXT, EGL_LINUX_DMA_BUF_EXT,
					   NULL, attrib_list);
	assert(image != EGL_NO_IMAGE_KHR);

	GLuint tex_in = 0;
        glGenTextures(1, &tex_in);
	glBindTexture(GL_TEXTURE_2D, tex_in);
	glEGLImageTargetTexture2DOES(GL_TEXTURE_2D, image);
	assert(glGetError() == GL_NO_ERROR);
	glBindImageTexture(0, tex_in, 0, GL_FALSE, 0, GL_READ_ONLY, GL_RGBA8);

	GLuint tex_out;
        glGenTextures(1, &tex_out);
	glBindTexture(GL_TEXTURE_2D, tex_out);
	glTextureStorage2D(tex_out, 1, GL_RGBA8, VK_TARGET_W, VK_TARGET_H);	
	glBindImageTexture(1, tex_out, 0, GL_FALSE, 0, GL_WRITE_ONLY, GL_RGBA8);

	glDispatchCompute(VK_TARGET_W >> 4, VK_TARGET_H >> 4, 1);
	glMemoryBarrier(GL_SHADER_IMAGE_ACCESS_BARRIER_BIT);

	assert(glGetError() == GL_NO_ERROR);

	GLubyte *result = calloc(1, VK_TARGET_W * VK_TARGET_H * 4);
	glGetTextureImage(tex_out, 0, GL_RGBA, GL_UNSIGNED_BYTE,
			  VK_TARGET_W * VK_TARGET_H * 4, result);
	assert(glGetError() == GL_NO_ERROR);

	assert(!writeImage("compute.png", VK_TARGET_W, VK_TARGET_H, VK_TARGET_W * 4,
			   result, "hello"));
}

void render_compute(void)
{
	RenderTargetInit("/dev/dri/renderD128");
	InitCompute();
	Compute();
}

int main(void)
{
	render_opengl();
	render_vulkan();
	//render_compute();
	return 0;
}