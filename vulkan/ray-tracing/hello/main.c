#include <stdio.h>
#include <assert.h>
#include <stdlib.h>
#include <string.h>
#include <inttypes.h>

#include <png.h>

#include <vulkan/vulkan.h>

#define TARGET_W 256
#define TARGET_H 256

#define ALIGN(x, a) (((x) + ((a) -1)) & ~((a) -1))
#define ARRAY_SIZE(a) (sizeof(a)/sizeof(a[0]))

static VkPhysicalDeviceMemoryProperties memoryProperties;
#define localMemoryTypeFlags VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT
#define hostVisibleMemoryTypeFlags (VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT | VK_MEMORY_PROPERTY_HOST_COHERENT_BIT)

static PFN_vkGetAccelerationStructureBuildSizesKHR _vkGetAccelerationStructureBuildSizesKHR;
static PFN_vkCreateAccelerationStructureKHR _vkCreateAccelerationStructureKHR;
static PFN_vkGetAccelerationStructureDeviceAddressKHR _vkGetAccelerationStructureDeviceAddressKHR;
static PFN_vkCmdBuildAccelerationStructuresKHR _vkCmdBuildAccelerationStructuresKHR;
static PFN_vkCreateRayTracingPipelinesKHR _vkCreateRayTracingPipelinesKHR;
static PFN_vkGetRayTracingShaderGroupHandlesKHR _vkGetRayTracingShaderGroupHandlesKHR;
static PFN_vkCmdTraceRaysKHR _vkCmdTraceRaysKHR;

static void init_raytracing_functions(VkDevice device)
{
  _vkGetAccelerationStructureBuildSizesKHR =
    (PFN_vkGetAccelerationStructureBuildSizesKHR)
    vkGetDeviceProcAddr(device, "vkGetAccelerationStructureBuildSizesKHR");
  _vkCreateAccelerationStructureKHR =
    (PFN_vkCreateAccelerationStructureKHR)
    vkGetDeviceProcAddr(device, "vkCreateAccelerationStructureKHR");
  _vkGetAccelerationStructureDeviceAddressKHR =
    (PFN_vkGetAccelerationStructureDeviceAddressKHR)
    vkGetDeviceProcAddr(device, "vkGetAccelerationStructureDeviceAddressKHR");
  _vkCmdBuildAccelerationStructuresKHR =
    (PFN_vkCmdBuildAccelerationStructuresKHR)
    vkGetDeviceProcAddr(device, "vkCmdBuildAccelerationStructuresKHR");
  _vkCreateRayTracingPipelinesKHR =
    (PFN_vkCreateRayTracingPipelinesKHR)
    vkGetDeviceProcAddr(device, "vkCreateRayTracingPipelinesKHR");
  _vkGetRayTracingShaderGroupHandlesKHR =
    (PFN_vkGetRayTracingShaderGroupHandlesKHR)
    vkGetDeviceProcAddr(device, "vkGetRayTracingShaderGroupHandlesKHR");
  _vkCmdTraceRaysKHR =
    (PFN_vkCmdTraceRaysKHR)
    vkGetDeviceProcAddr(device, "vkCmdTraceRaysKHR");
}

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

  assert((f = fopen(name, "rb")) != NULL);

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

static int
get_memory_type_index(VkMemoryRequirements *requirements,
		      VkMemoryPropertyFlags flags)
{
  for (int i = 0; i < memoryProperties.memoryTypeCount; i++) {
    if ((memoryProperties.memoryTypes[i].propertyFlags & flags) &&
	(requirements->memoryTypeBits & (1 << i)))
      return i;
  }
  assert(0 && "No suitable memory type found");
  return -1;
}

struct buffer {
  VkBuffer buffer;
  VkDeviceMemory memory;
  VkDeviceAddress address;
};

static void create_buffer(VkDevice device,
			  struct buffer *buffer,
			  VkDeviceSize size,
			  VkBufferUsageFlags usage,
			  VkMemoryPropertyFlags flags)
{
  VkBufferCreateInfo info = {
    .sType = VK_STRUCTURE_TYPE_BUFFER_CREATE_INFO,
    .size = size,
    .usage = usage,
  };
  assert(vkCreateBuffer(device, &info, NULL, &buffer->buffer) == VK_SUCCESS);

  VkMemoryRequirements requirements;
  vkGetBufferMemoryRequirements(device, buffer->buffer, &requirements);

  VkMemoryAllocateFlagsInfo alloc_flags = {
    .sType = VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_FLAGS_INFO,
    .flags = VK_MEMORY_ALLOCATE_DEVICE_ADDRESS_BIT,
  };
  VkMemoryAllocateInfo alloc_info = {
    .sType = VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_INFO,
    .allocationSize = requirements.size,
    .memoryTypeIndex = get_memory_type_index(&requirements, flags),
  };
  if (usage & VK_BUFFER_USAGE_SHADER_DEVICE_ADDRESS_BIT)
    alloc_info.pNext = &alloc_flags;
  assert(vkAllocateMemory(device, &alloc_info, NULL, &buffer->memory) == VK_SUCCESS);
  assert(vkBindBufferMemory(device, buffer->buffer, buffer->memory, 0) == VK_SUCCESS);

  if (usage & VK_BUFFER_USAGE_SHADER_DEVICE_ADDRESS_BIT) {
    VkBufferDeviceAddressInfo address_info = {
      .sType = VK_STRUCTURE_TYPE_BUFFER_DEVICE_ADDRESS_INFO,
      .buffer = buffer->buffer,
    };
    buffer->address = vkGetBufferDeviceAddress(device, &address_info);
    assert(buffer->address != 0);
  }
}

static VkAccelerationStructureKHR
create_as(VkDevice device,
	  VkCommandBuffer commandBuffer,
	  uint32_t scratchAlignment,
	  VkAccelerationStructureTypeKHR type,
	  VkAccelerationStructureGeometryKHR *geometry,
	  VkAccelerationStructureBuildRangeInfoKHR *range)
{
  VkAccelerationStructureBuildGeometryInfoKHR buildInfo = {
    .sType = VK_STRUCTURE_TYPE_ACCELERATION_STRUCTURE_BUILD_GEOMETRY_INFO_KHR,
    .type = type,
    .flags = VK_BUILD_ACCELERATION_STRUCTURE_PREFER_FAST_TRACE_BIT_KHR,
    .mode = VK_BUILD_ACCELERATION_STRUCTURE_MODE_BUILD_KHR,
    .geometryCount = 1,
    .pGeometries = geometry,
  };
  VkAccelerationStructureBuildSizesInfoKHR sizeInfo = {
    .sType = VK_STRUCTURE_TYPE_ACCELERATION_STRUCTURE_BUILD_SIZES_INFO_KHR,
  };

  uint32_t maxPrimitiveCount = range->primitiveCount;
  _vkGetAccelerationStructureBuildSizesKHR(device,
					   VK_ACCELERATION_STRUCTURE_BUILD_TYPE_DEVICE_KHR,
					   &buildInfo,
					   &maxPrimitiveCount,
					   &sizeInfo);

  VkDeviceSize scratchSize = ALIGN(sizeInfo.buildScratchSize, scratchAlignment);

  struct buffer scratchBuffer;
  create_buffer(device, &scratchBuffer, scratchSize,
		VK_BUFFER_USAGE_SHADER_DEVICE_ADDRESS_BIT |
		VK_BUFFER_USAGE_STORAGE_BUFFER_BIT,
		localMemoryTypeFlags);

  struct buffer asBuffer;
  create_buffer(device, &asBuffer, sizeInfo.accelerationStructureSize,
		VK_BUFFER_USAGE_ACCELERATION_STRUCTURE_STORAGE_BIT_KHR |
		VK_BUFFER_USAGE_SHADER_DEVICE_ADDRESS_BIT,
		localMemoryTypeFlags);

  VkAccelerationStructureKHR as;
  {
    VkAccelerationStructureCreateInfoKHR info = {
      .sType = VK_STRUCTURE_TYPE_ACCELERATION_STRUCTURE_CREATE_INFO_KHR,
      .type = type,
      .buffer = asBuffer.buffer,
      .size = sizeInfo.accelerationStructureSize,
    };
    assert(_vkCreateAccelerationStructureKHR(device, &info, NULL, &as) == VK_SUCCESS);
  }

  buildInfo.dstAccelerationStructure = as;
  buildInfo.scratchData.deviceAddress = scratchBuffer.address;
  const VkAccelerationStructureBuildRangeInfoKHR *rangeInfos[] = {
    range,
  };
  _vkCmdBuildAccelerationStructuresKHR(commandBuffer,
				       1,
				       &buildInfo,
				       rangeInfos);  
  return as;
}

static VkAccelerationStructureKHR
create_blas(VkDevice device,
	    VkCommandBuffer commandBuffer,
	    uint32_t scratchAlignment)
{
  float vertex[] = {
    0,         0,        1,
    0,         TARGET_H, 1,
    TARGET_W,  0,        1,
  };
  struct buffer vertexBuffer;
  {
    create_buffer(device, &vertexBuffer, sizeof(vertex),
		  VK_BUFFER_USAGE_SHADER_DEVICE_ADDRESS_BIT |
		  VK_BUFFER_USAGE_ACCELERATION_STRUCTURE_BUILD_INPUT_READ_ONLY_BIT_KHR |
		  VK_BUFFER_USAGE_STORAGE_BUFFER_BIT,
		  hostVisibleMemoryTypeFlags);
    void* data;
    assert(vkMapMemory(device, vertexBuffer.memory, 0, VK_WHOLE_SIZE, 0, &data) == VK_SUCCESS);
    memcpy(data, vertex, sizeof(vertex));
    vkUnmapMemory(device, vertexBuffer.memory);
  }
  VkAccelerationStructureGeometryTrianglesDataKHR triangles = {
    .sType = VK_STRUCTURE_TYPE_ACCELERATION_STRUCTURE_GEOMETRY_TRIANGLES_DATA_KHR,
    .vertexFormat = VK_FORMAT_R32G32B32_SFLOAT,
    .vertexData.deviceAddress = vertexBuffer.address,
    .vertexStride = 3 * sizeof(float),
    .maxVertex = sizeof(vertex) / (3 * sizeof(float)) - 1,
    .indexType = VK_INDEX_TYPE_NONE_KHR,
  };
  VkAccelerationStructureGeometryKHR geometry = {
    .sType = VK_STRUCTURE_TYPE_ACCELERATION_STRUCTURE_GEOMETRY_KHR,
    .geometryType = VK_GEOMETRY_TYPE_TRIANGLES_KHR,
    .flags = VK_GEOMETRY_OPAQUE_BIT_KHR,
    .geometry.triangles = triangles,
  };
  VkAccelerationStructureBuildRangeInfoKHR range = {
    .primitiveCount = sizeof(vertex) / (3 * sizeof(float)) / 3,
  };
  return create_as(device, commandBuffer, scratchAlignment,
		   VK_ACCELERATION_STRUCTURE_TYPE_BOTTOM_LEVEL_KHR,
		   &geometry, &range);
}

static VkAccelerationStructureKHR
create_tlas(VkDevice device,
	    VkCommandBuffer commandBuffer,
	    uint32_t scratchAlignment,
	    VkAccelerationStructureKHR blas)
{
  VkDeviceAddress blasAddress;
  {
    VkAccelerationStructureDeviceAddressInfoKHR info = {
      .sType = VK_STRUCTURE_TYPE_ACCELERATION_STRUCTURE_DEVICE_ADDRESS_INFO_KHR,
      .accelerationStructure = blas,
    };
    blasAddress = _vkGetAccelerationStructureDeviceAddressKHR(device, &info);
    assert(blasAddress != 0);
  }

  struct buffer instanceBuffer;
  {
    VkAccelerationStructureInstanceKHR instance = {
      .transform.matrix = {
	{1, 0, 0, 0},
	{0, 1, 0, 0},
	{0, 0, 1, 0},
      },
      .mask = 0xFF,
      .flags = VK_GEOMETRY_INSTANCE_TRIANGLE_FACING_CULL_DISABLE_BIT_KHR,
      .accelerationStructureReference = blasAddress,
    };
    create_buffer(device, &instanceBuffer, sizeof(instance),
		  VK_BUFFER_USAGE_SHADER_DEVICE_ADDRESS_BIT |
		  VK_BUFFER_USAGE_ACCELERATION_STRUCTURE_BUILD_INPUT_READ_ONLY_BIT_KHR,
		  hostVisibleMemoryTypeFlags);
    void* data;
    assert(vkMapMemory(device, instanceBuffer.memory, 0, VK_WHOLE_SIZE, 0, &data) == VK_SUCCESS);
    memcpy(data, &instance, sizeof(instance));
    vkUnmapMemory(device, instanceBuffer.memory);
  }
  VkAccelerationStructureGeometryInstancesDataKHR geomInstances = {
    .sType = VK_STRUCTURE_TYPE_ACCELERATION_STRUCTURE_GEOMETRY_INSTANCES_DATA_KHR,
    .data.deviceAddress = instanceBuffer.address,
  };
  VkAccelerationStructureGeometryKHR geometry = {
    .sType = VK_STRUCTURE_TYPE_ACCELERATION_STRUCTURE_GEOMETRY_KHR,
    .geometryType = VK_GEOMETRY_TYPE_INSTANCES_KHR,
    .flags = VK_GEOMETRY_OPAQUE_BIT_KHR,
    .geometry.instances = geomInstances,
  };
  VkAccelerationStructureBuildRangeInfoKHR range = {
    .primitiveCount = 1,
  };  
  return create_as(device, commandBuffer, scratchAlignment,
		   VK_ACCELERATION_STRUCTURE_TYPE_TOP_LEVEL_KHR,
		   &geometry, &range);
}

static VkAccelerationStructureKHR
create_acceleration_structure(VkDevice device,
			      VkCommandBuffer commandBuffer,
			      uint32_t scratchAlignment)
{
  VkAccelerationStructureKHR blas =
    create_blas(device, commandBuffer, scratchAlignment);

  VkMemoryBarrier barrier = {
    .sType = VK_STRUCTURE_TYPE_MEMORY_BARRIER,
    .srcAccessMask = VK_ACCESS_ACCELERATION_STRUCTURE_WRITE_BIT_KHR,
    .dstAccessMask = VK_ACCESS_ACCELERATION_STRUCTURE_READ_BIT_KHR
  };

  vkCmdPipelineBarrier(commandBuffer,
		       VK_PIPELINE_STAGE_ACCELERATION_STRUCTURE_BUILD_BIT_KHR,
		       VK_PIPELINE_STAGE_ACCELERATION_STRUCTURE_BUILD_BIT_KHR,
		       0, 1, &barrier, 0, NULL, 0, NULL);

  return create_tlas(device, commandBuffer, scratchAlignment, blas);
}

static VkDescriptorSet
create_descriptor_set(VkDevice device,
		      VkDescriptorSetLayout descriptorSetLayout,
		      VkImageView image,
		      VkAccelerationStructureKHR as)
{
  VkDescriptorPool descriptorPool;
  {
    VkDescriptorPoolSize sizes[] = {
      [0] = {
	.type = VK_DESCRIPTOR_TYPE_ACCELERATION_STRUCTURE_KHR,
	.descriptorCount = 1,
      },
      [1] = {
	.type = VK_DESCRIPTOR_TYPE_STORAGE_IMAGE,
	.descriptorCount = 1,
      },
    };
    VkDescriptorPoolCreateInfo info = {
      .sType = VK_STRUCTURE_TYPE_DESCRIPTOR_POOL_CREATE_INFO,
      .maxSets = 1,
      .poolSizeCount = ARRAY_SIZE(sizes),
      .pPoolSizes = sizes,
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

  VkWriteDescriptorSet writes[] = {
    [0] = {
      .sType = VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET,
      .pNext = &(VkWriteDescriptorSetAccelerationStructureKHR){
	.sType = VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET_ACCELERATION_STRUCTURE_KHR,
	.accelerationStructureCount = 1,
	.pAccelerationStructures = &as,
      },
      .dstSet = descriptorSet,
      .dstBinding = 0,
      .descriptorCount = 1,
      .descriptorType = VK_DESCRIPTOR_TYPE_ACCELERATION_STRUCTURE_KHR,
    },
    [1] = {
      .sType = VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET,
      .dstSet = descriptorSet,
      .dstBinding = 1,
      .descriptorCount = 1,
      .descriptorType = VK_DESCRIPTOR_TYPE_STORAGE_IMAGE,
      .pImageInfo = &(VkDescriptorImageInfo){
	.imageView = image,
	.imageLayout = VK_IMAGE_LAYOUT_GENERAL,
      },
    },
  };
  vkUpdateDescriptorSets(device, ARRAY_SIZE(writes), writes, 0, NULL);

  return descriptorSet;
}

static VkPipeline
create_ray_tracing_pipeline(VkDevice device, VkPipelineLayout pipelineLayout)
{
  VkShaderModule rgen = createShaderModule(device, "rgen.spv");
  VkShaderModule rmiss = createShaderModule(device, "rmiss.spv");
  VkShaderModule chit = createShaderModule(device, "rchit.spv");

  VkPipelineShaderStageCreateInfo stages[] = {
    [0] = {
      .sType = VK_STRUCTURE_TYPE_PIPELINE_SHADER_STAGE_CREATE_INFO,
      .stage = VK_SHADER_STAGE_RAYGEN_BIT_KHR,
      .module = rgen,
      .pName = "main",
    },
    [1] = {
      .sType = VK_STRUCTURE_TYPE_PIPELINE_SHADER_STAGE_CREATE_INFO,
      .stage = VK_SHADER_STAGE_MISS_BIT_KHR,
      .module = rmiss,
      .pName = "main",
    },
    [2] = {
      .sType = VK_STRUCTURE_TYPE_PIPELINE_SHADER_STAGE_CREATE_INFO,
      .stage = VK_SHADER_STAGE_CLOSEST_HIT_BIT_KHR,
      .module = chit,
      .pName = "main",
    },
  };

  VkRayTracingShaderGroupCreateInfoKHR groups[] = {
    [0] = {
      .sType = VK_STRUCTURE_TYPE_RAY_TRACING_SHADER_GROUP_CREATE_INFO_KHR,
      .type = VK_RAY_TRACING_SHADER_GROUP_TYPE_GENERAL_KHR,
      .generalShader = 0, /* ray gen shader index in stages[] */
      .closestHitShader = VK_SHADER_UNUSED_KHR,
      .anyHitShader = VK_SHADER_UNUSED_KHR,
      .intersectionShader = VK_SHADER_UNUSED_KHR,
    },
    [1] = {
      .sType = VK_STRUCTURE_TYPE_RAY_TRACING_SHADER_GROUP_CREATE_INFO_KHR,
      .type = VK_RAY_TRACING_SHADER_GROUP_TYPE_GENERAL_KHR,
      .generalShader = 1, /* miss shader index in stages[] */
      .closestHitShader = VK_SHADER_UNUSED_KHR,
      .anyHitShader = VK_SHADER_UNUSED_KHR,
      .intersectionShader = VK_SHADER_UNUSED_KHR,
    },
    [2] = {
      .sType = VK_STRUCTURE_TYPE_RAY_TRACING_SHADER_GROUP_CREATE_INFO_KHR,
      .type = VK_RAY_TRACING_SHADER_GROUP_TYPE_TRIANGLES_HIT_GROUP_KHR,
      .closestHitShader = 2, /* closest hit shader index in stages[] */
      .generalShader = VK_SHADER_UNUSED_KHR,
      .anyHitShader = VK_SHADER_UNUSED_KHR,
      .intersectionShader = VK_SHADER_UNUSED_KHR,
    },
  };

  VkPipeline pipeline;
  {
    VkRayTracingPipelineCreateInfoKHR info = {
      .sType = VK_STRUCTURE_TYPE_RAY_TRACING_PIPELINE_CREATE_INFO_KHR,
      .stageCount = ARRAY_SIZE(stages),
      .pStages = stages,
      .groupCount = ARRAY_SIZE(groups),
      .pGroups = groups,
      .maxPipelineRayRecursionDepth = 3,
      .layout = pipelineLayout,
    };
    assert(_vkCreateRayTracingPipelinesKHR(device, NULL, NULL, 1, &info, NULL, &pipeline) == VK_SUCCESS);
  }
  return pipeline;
}

static void
create_shader_binding_tables(VkDevice device,
			     VkPipeline pipeline,
			     VkPhysicalDeviceRayTracingPipelinePropertiesKHR *rtProp,
			     VkStridedDeviceAddressRegionKHR *raygenSbt,
			     VkStridedDeviceAddressRegionKHR *missSbt,
			     VkStridedDeviceAddressRegionKHR *hitSbt)
{
  uint32_t handleSize = rtProp->shaderGroupHandleSize;
  uint32_t handleAlignment = rtProp->shaderGroupHandleAlignment;
  uint32_t baseAlignment = rtProp->shaderGroupBaseAlignment;
  uint32_t groupCount = 3; // raygen, miss, hit

  size_t sbtSize = groupCount * handleSize;
  uint8_t handles[sbtSize];
  assert(_vkGetRayTracingShaderGroupHandlesKHR(device, pipeline,
					       0, groupCount,
					       sbtSize, handles) == VK_SUCCESS);

  uint32_t alignedHandleSize = ALIGN(handleSize, handleAlignment);
  uint32_t raygenOffset = 0;
  uint32_t missOffset = ALIGN(raygenOffset + alignedHandleSize, baseAlignment);
  uint32_t hitOffset = ALIGN(missOffset + alignedHandleSize, baseAlignment);
  
  size_t bufferSize = hitOffset + alignedHandleSize;
  struct buffer sbtBuffer;
  create_buffer(device, &sbtBuffer, bufferSize,
		VK_BUFFER_USAGE_SHADER_DEVICE_ADDRESS_BIT |
		VK_BUFFER_USAGE_SHADER_BINDING_TABLE_BIT_KHR,
		hostVisibleMemoryTypeFlags);
  void* data;
  assert(vkMapMemory(device, sbtBuffer.memory, 0, VK_WHOLE_SIZE, 0, &data) == VK_SUCCESS);

  // Ray generation shader (group 0)
  memcpy(data + raygenOffset, handles + 0 * handleSize, handleSize);
  raygenSbt->deviceAddress = sbtBuffer.address + raygenOffset;
  raygenSbt->stride = alignedHandleSize;
  raygenSbt->size = alignedHandleSize;

  // Miss shader (group 1)
  memcpy(data + missOffset, handles + 1 * handleSize, handleSize);
  missSbt->deviceAddress = sbtBuffer.address + missOffset;
  missSbt->stride = alignedHandleSize;
  missSbt->size = alignedHandleSize;

  // Hit shader (group 2)
  memcpy(data + hitOffset, handles + 2 * handleSize, handleSize);
  hitSbt->deviceAddress = sbtBuffer.address + hitOffset;
  hitSbt->stride = alignedHandleSize;
  hitSbt->size = alignedHandleSize;

  vkUnmapMemory(device, sbtBuffer.memory);
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
  uint32_t scratchAlignment;
  VkPhysicalDeviceRayTracingPipelinePropertiesKHR raytracing_prop = {
    .sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_RAY_TRACING_PIPELINE_PROPERTIES_KHR,
  };
  {
    uint32_t physCount = 0;
    assert(vkEnumeratePhysicalDevices(inst, &physCount, NULL) == VK_SUCCESS);

    VkPhysicalDevice *devs = calloc(sizeof(*devs), physCount);
    assert(vkEnumeratePhysicalDevices(inst, &physCount, devs) == VK_SUCCESS);

    VkPhysicalDeviceAccelerationStructurePropertiesKHR accel_prop = {
      .sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_ACCELERATION_STRUCTURE_PROPERTIES_KHR,
      .pNext = &raytracing_prop,
    };
    VkPhysicalDeviceProperties2 device_prop = {
      .sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_PROPERTIES_2,
      .pNext = &accel_prop,
    };

    int i;
    for (i = 0; i < physCount; i++) {
      VkPhysicalDeviceAccelerationStructureFeaturesKHR accel = {
	.sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_ACCELERATION_STRUCTURE_FEATURES_KHR,
      };
      VkPhysicalDeviceRayTracingPipelineFeaturesKHR raytracing = {
	.sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_RAY_TRACING_PIPELINE_FEATURES_KHR,
	.pNext = &accel,
      };
      VkPhysicalDeviceFeatures2 device_features = {
	.sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_FEATURES_2,
	.pNext = &raytracing,
      };
      vkGetPhysicalDeviceFeatures2(devs[i], &device_features);

      if (accel.accelerationStructure && raytracing.rayTracingPipeline) {
	vkGetPhysicalDeviceProperties2(devs[i], &device_prop);

	if (device_prop.properties.deviceType == VK_PHYSICAL_DEVICE_TYPE_INTEGRATED_GPU ||
	    device_prop.properties.deviceType == VK_PHYSICAL_DEVICE_TYPE_DISCRETE_GPU) {
	  scratchAlignment = accel_prop.minAccelerationStructureScratchOffsetAlignment;
	  break;
	}
      }
    }
    assert(i < physCount);
    phys = devs[i];
    free(devs);
  }

  vkGetPhysicalDeviceMemoryProperties(phys, &memoryProperties);

  unsigned queueFamilyIndex = 0;
  {
    uint32_t count = 0;
    vkGetPhysicalDeviceQueueFamilyProperties(phys, &count, NULL);

    VkQueueFamilyProperties properties[count];
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
    VkPhysicalDeviceBufferDeviceAddressFeatures address_feature = {
      .sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_BUFFER_DEVICE_ADDRESS_FEATURES,
      .bufferDeviceAddress = VK_TRUE,
    };
    VkPhysicalDeviceAccelerationStructureFeaturesKHR accel_feature = {
      .sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_ACCELERATION_STRUCTURE_FEATURES_KHR,
      .pNext = &address_feature,
      .accelerationStructure = VK_TRUE,
    };
    VkPhysicalDeviceRayTracingPipelineFeaturesKHR raytracing_feature = {
      .sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_RAY_TRACING_PIPELINE_FEATURES_KHR,
      .rayTracingPipeline = VK_TRUE,
      .pNext = &accel_feature,
    };
    const char *extensions[] = {
      VK_KHR_ACCELERATION_STRUCTURE_EXTENSION_NAME,
      VK_KHR_RAY_TRACING_PIPELINE_EXTENSION_NAME,
      VK_KHR_DEFERRED_HOST_OPERATIONS_EXTENSION_NAME,
    };
    VkDeviceCreateInfo info = {
      .sType = VK_STRUCTURE_TYPE_DEVICE_CREATE_INFO,
      .pNext = &raytracing_feature,
      .queueCreateInfoCount = 1,
      .pQueueCreateInfos = &queueInfo,
      .enabledExtensionCount = ARRAY_SIZE(extensions),
      .ppEnabledExtensionNames = extensions,
    };
    assert(vkCreateDevice(phys, &info, NULL, &device) == VK_SUCCESS);
  }

  init_raytracing_functions(device);

  VkQueue queue;
  vkGetDeviceQueue(device, queueFamilyIndex, 0, &queue);

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

  VkImage image;
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
    assert(vkCreateImage(device, &info, NULL, &image) == VK_SUCCESS);
  }
  VkDeviceMemory imageMemory;
  {
    VkMemoryRequirements requirements;
    vkGetImageMemoryRequirements(device, image, &requirements);

    VkMemoryAllocateInfo info = {
      .sType = VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_INFO,
      .allocationSize = requirements.size,
      .memoryTypeIndex = get_memory_type_index(&requirements, hostVisibleMemoryTypeFlags),
    };
    assert(vkAllocateMemory(device, &info, NULL, &imageMemory) == VK_SUCCESS);
    assert(vkBindImageMemory(device, image, imageMemory, 0) == VK_SUCCESS);
  }
  VkImageView imageView;
  {
    VkImageViewCreateInfo info = {
      .sType = VK_STRUCTURE_TYPE_IMAGE_VIEW_CREATE_INFO,
      .image = image,
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
    assert(vkCreateImageView(device, &info, NULL, &imageView) == VK_SUCCESS);
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
      .srcAccessMask = 0,
      .dstAccessMask = VK_ACCESS_SHADER_WRITE_BIT,
      .oldLayout = VK_IMAGE_LAYOUT_UNDEFINED,
      .newLayout = VK_IMAGE_LAYOUT_GENERAL,
      .srcQueueFamilyIndex = VK_QUEUE_FAMILY_IGNORED,
      .dstQueueFamilyIndex = VK_QUEUE_FAMILY_IGNORED,
      .image = image,
      .subresourceRange = {
	.aspectMask = VK_IMAGE_ASPECT_COLOR_BIT,
	.levelCount = 1,
	.layerCount = 1,
      },
    };
    vkCmdPipelineBarrier(commandBuffer,
			 VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT,
			 VK_PIPELINE_STAGE_RAY_TRACING_SHADER_BIT_KHR,
			 0, 0, NULL, 0, NULL, 1, &barrier);
  }

  VkAccelerationStructureKHR as =
    create_acceleration_structure(device, commandBuffer, scratchAlignment);

  {
    /* barrier between acceleration structure build and ray tracing */
    VkMemoryBarrier barrier = {
      .sType = VK_STRUCTURE_TYPE_MEMORY_BARRIER,
      .srcAccessMask = VK_ACCESS_ACCELERATION_STRUCTURE_WRITE_BIT_KHR,
      .dstAccessMask = VK_ACCESS_ACCELERATION_STRUCTURE_READ_BIT_KHR
    };
    vkCmdPipelineBarrier(commandBuffer,
			 VK_PIPELINE_STAGE_ACCELERATION_STRUCTURE_BUILD_BIT_KHR,
			 VK_PIPELINE_STAGE_RAY_TRACING_SHADER_BIT_KHR,
			 0, 1, &barrier, 0, NULL, 0, NULL);
  }

  VkDescriptorSetLayout descriptorSetLayout;
  {
    VkDescriptorSetLayoutBinding bindings[] = {
      [0] = {
	.binding = 0,
	.descriptorType = VK_DESCRIPTOR_TYPE_ACCELERATION_STRUCTURE_KHR,
	.descriptorCount = 1,
	.stageFlags = VK_SHADER_STAGE_RAYGEN_BIT_KHR,
      },
      [1] = {
	.binding = 1,
	.descriptorType = VK_DESCRIPTOR_TYPE_STORAGE_IMAGE,
	.descriptorCount = 1,
	.stageFlags = VK_SHADER_STAGE_RAYGEN_BIT_KHR,
      },
    };

    VkDescriptorSetLayoutCreateInfo info = {
      .sType = VK_STRUCTURE_TYPE_DESCRIPTOR_SET_LAYOUT_CREATE_INFO,
      .bindingCount = ARRAY_SIZE(bindings),
      .pBindings = bindings,
    };

    assert(vkCreateDescriptorSetLayout(device, &info, NULL, &descriptorSetLayout) == VK_SUCCESS);
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

  VkPipeline pipeline = create_ray_tracing_pipeline(device, pipelineLayout);
  vkCmdBindPipeline(commandBuffer, VK_PIPELINE_BIND_POINT_RAY_TRACING_KHR, pipeline);

  VkDescriptorSet descriptorSet =
    create_descriptor_set(device, descriptorSetLayout, imageView, as);
  vkCmdBindDescriptorSets(commandBuffer,
			  VK_PIPELINE_BIND_POINT_RAY_TRACING_KHR,
			  pipelineLayout,
			  0, 1, &descriptorSet,
			  0, NULL);

  VkStridedDeviceAddressRegionKHR raygenSbt = {0};
  VkStridedDeviceAddressRegionKHR missSbt = {0};
  VkStridedDeviceAddressRegionKHR hitSbt = {0};
  VkStridedDeviceAddressRegionKHR callableSbt = {0};

  create_shader_binding_tables(device, pipeline, &raytracing_prop,
			       &raygenSbt, &missSbt, &hitSbt);

  _vkCmdTraceRaysKHR(commandBuffer, &raygenSbt, &missSbt, &hitSbt, &callableSbt,
		     TARGET_W, TARGET_H, 1);

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
    assert(vkMapMemory(device, imageMemory, 0, VK_WHOLE_SIZE, 0, &data) == VK_SUCCESS);

    assert(!writeImage("screenshot.png", TARGET_W, TARGET_H, TARGET_W * 4,
		       data, "hello"));

    vkUnmapMemory(device, imageMemory);

    printf("success\n");
  }
}
