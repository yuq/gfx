#include <stdio.h>
#include <assert.h>
#include <stdlib.h>
#include <string.h>

#include <unistd.h>
#include <time.h>

#include <vulkan/vulkan.h>

#define TARGET_SIZE 256

void print_mem_prop(VkMemoryPropertyFlagBits flags)
{
	for (int i = 0; i < 32; i++) {
		VkMemoryPropertyFlagBits bit = 1 << i;
		if (flags & bit) {
			switch (bit) {
			case VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT:
				printf(" dev_loc");
				break;
			case VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT:
				printf(" host_vis");
				break;
			case VK_MEMORY_PROPERTY_HOST_COHERENT_BIT:
				printf(" host_cohe");
				break;
			case VK_MEMORY_PROPERTY_HOST_CACHED_BIT:
				printf(" host_cached");
				break;
			case VK_MEMORY_PROPERTY_LAZILY_ALLOCATED_BIT:
				printf(" lazy");
				break;
			case VK_MEMORY_PROPERTY_PROTECTED_BIT:
				printf(" protect");
				break;
			case VK_MEMORY_PROPERTY_DEVICE_COHERENT_BIT_AMD:
				printf(" dev_cohe");
				break;
			case VK_MEMORY_PROPERTY_DEVICE_UNCACHED_BIT_AMD:
				printf(" dev_uncached");
				break;
			case VK_MEMORY_PROPERTY_RDMA_CAPABLE_BIT_NV:
				printf(" rdma");
				break;
			}
		}
	}
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

#define MAX_MEM_TYPE 16

	int memoryTypeIndex[MAX_MEM_TYPE] = {};
	int numMemoryTypes = 0;
	for (int i = 0; i < memoryProperties.memoryTypeCount; i++) {
		if (memoryProperties.memoryTypes[i].propertyFlags &
		    VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT) {
		        memoryTypeIndex[numMemoryTypes++] = i;
		}
	}
	assert(numMemoryTypes > 0 && numMemoryTypes <= MAX_MEM_TYPE);

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

	printf("GPU memory write %d dword:\n", TARGET_SIZE);

	for (int i = 0; i < numMemoryTypes; i++) {
		VkDeviceMemory memory;
		{
			VkMemoryAllocateInfo info = {
				.sType = VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_INFO,
				.allocationSize = TARGET_SIZE * 4,
				.memoryTypeIndex = memoryTypeIndex[i],
			};
			assert(vkAllocateMemory(device, &info, NULL, &memory) == VK_SUCCESS);
		}

		{
			void* data;
			assert(vkMapMemory(device, memory, 0, TARGET_SIZE * 4, 0, &data) == VK_SUCCESS);

			struct timespec ts1, ts2;
			assert(!clock_gettime(CLOCK_MONOTONIC, &ts1));

			for (int i = 0; i < TARGET_SIZE; i++)
				((uint32_t *)data)[i] = i;

			assert(!clock_gettime(CLOCK_MONOTONIC, &ts2));

			vkUnmapMemory(device, memory);

			double a = ts2.tv_sec - ts1.tv_sec;
			double b = ts2.tv_nsec - ts1.tv_nsec;
			double c = a * 1000000000 + b;
			printf("time: %f nsec, prop:", c);

			VkMemoryType *type = memoryProperties.memoryTypes + memoryTypeIndex[i];
			print_mem_prop(type->propertyFlags);
			printf("\n");
		}
	}

	printf("\nGPU memory write %d dword:\n", TARGET_SIZE);

	{
		uint32_t data[TARGET_SIZE];

		struct timespec ts1, ts2;
		assert(!clock_gettime(CLOCK_MONOTONIC, &ts1));

		for (int i = 0; i < TARGET_SIZE; i++)
			data[i] = i;

		assert(!clock_gettime(CLOCK_MONOTONIC, &ts2));

		double a = ts2.tv_sec - ts1.tv_sec;
		double b = ts2.tv_nsec - ts1.tv_nsec;
		double c = a * 1000000000 + b;
		printf("time: %f nsec\n", c);
	}

	return 0;
}
