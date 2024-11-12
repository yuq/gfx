#include <cassert>
#include <iostream>

#include <vulkan/vulkan.h>
#include <vulkan/vulkan_extension_inspection.hpp>

int main(void)
{
	VkExtensionProperties *inst_exts;
	unsigned num_inst_exts;
	{
		assert(vkEnumerateInstanceExtensionProperties(NULL, &num_inst_exts, NULL) == VK_SUCCESS);
		inst_exts = new VkExtensionProperties[num_inst_exts];
		assert(vkEnumerateInstanceExtensionProperties(NULL, &num_inst_exts, inst_exts) == VK_SUCCESS);
	}

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

		VkPhysicalDevice *devs = new VkPhysicalDevice[physCount];
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
		delete devs;
	}

	VkExtensionProperties *dev_exts;
	unsigned num_dev_exts;
	{
		assert(vkEnumerateDeviceExtensionProperties(phys, NULL, &num_dev_exts, NULL) == VK_SUCCESS);
		dev_exts = new VkExtensionProperties[num_dev_exts];
		assert(vkEnumerateDeviceExtensionProperties(phys, NULL, &num_dev_exts, dev_exts) == VK_SUCCESS);
	}

	std::map<std::string, std::string> deprecatedExtensions = VULKAN_HPP_NAMESPACE::getDeprecatedExtensions();
	std::map<std::string, std::string> obsoletedExtensions = VULKAN_HPP_NAMESPACE::getObsoletedExtensions();
	std::map<std::string, std::string> promotedExtensions = VULKAN_HPP_NAMESPACE::getPromotedExtensions();

	std::set<std::string> all_inst_exts = VULKAN_HPP_NAMESPACE::getInstanceExtensions();
	for (int i = 0; i < num_inst_exts; i++)
		all_inst_exts.erase(inst_exts[i].extensionName);

	std::cout << "Missing instance extensions:\n";
	for (std::string ext : all_inst_exts) {
		if (!deprecatedExtensions.contains(ext) &&
		    !obsoletedExtensions.contains(ext) &&
		    !promotedExtensions.contains(ext))
			std::cout << ext << std::endl;
	}
	std::cout << std::endl;

	std::set<std::string> all_dev_exts = VULKAN_HPP_NAMESPACE::getDeviceExtensions();
	for (int i = 0; i < num_dev_exts; i++)
		all_dev_exts.erase(dev_exts[i].extensionName);

	std::cout << "Missing device extensions:\n";
	for (std::string ext : all_dev_exts) {
		if (!deprecatedExtensions.contains(ext) &&
		    !obsoletedExtensions.contains(ext) &&
		    !promotedExtensions.contains(ext))
			std::cout << ext << std::endl;
	}
	std::cout << std::endl;
}
