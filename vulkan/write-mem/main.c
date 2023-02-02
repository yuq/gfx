#include <stdio.h>
#include <assert.h>
#include <stdlib.h>
#include <string.h>

#include <unistd.h>
#include <time.h>

#include <vulkan/vulkan.h>

#define TARGET_SIZE 256

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

	int MemoryTypeIndex = -1;
	for (int i = 0; i < memoryProperties.memoryTypeCount; i++) {
		if (memoryProperties.memoryTypes[i].propertyFlags &
		    VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT) {
			MemoryTypeIndex = i;
			break;
		}
	}
	assert(MemoryTypeIndex >= 0);

	VkDevice device;
	{
		VkDeviceCreateInfo info = {
			.sType = VK_STRUCTURE_TYPE_DEVICE_CREATE_INFO,
		};
		assert(vkCreateDevice(phys, &info, NULL, &device) == VK_SUCCESS);
	}

	VkDeviceMemory memory;
	{
		VkMemoryAllocateInfo info = {
			.sType = VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_INFO,
			.allocationSize = TARGET_SIZE * 4,
			.memoryTypeIndex = MemoryTypeIndex,
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
		printf("GPU memory write %d dword cost %f nsec\n", TARGET_SIZE, c);
	}

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
		printf("CPU memory write %d dword cost %f nsec\n", TARGET_SIZE, c);
	}

	return 0;
}
