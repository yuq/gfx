#include <stdio.h>
#include <assert.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <dirent.h>
#include <unistd.h>
#include <xf86drm.h>
#include <xf86drmMode.h>
#include <unistd.h>
#include <fcntl.h>

int main(int argc, char **argv)
{
  int fd, newlyopened;
  drmVersionPtr retval;
  char *busid;
  drmDevicePtr dev;
  //*
  fd = drmOpen(NULL, "pci:0000:00:02.0");
  assert(fd >= 0);
  
  retval = drmGetVersion(fd);
  printf("name=%s\n", retval->name);
  drmFreeVersion(retval);

  busid = drmGetBusid(fd);
  printf("busid=%s\n", busid);
  drmFreeBusid(busid);

  assert(!drmGetDevice(fd, &dev));
  printf("pci:%04x:%02x:%02x.%d\n",
	   dev->businfo.pci->domain,
	   dev->businfo.pci->bus,
	   dev->businfo.pci->dev,
	   dev->businfo.pci->func);

  drmClose(fd);
  //*/

  fd = drmOpenOnceWithType("pci:0000:01:00.0", &newlyopened, DRM_NODE_PRIMARY);
  //fd = open("/dev/dri/card0", O_RDWR);
  assert(fd >= 0);
  
  retval = drmGetVersion(fd);
  printf("name=%s\n", retval->name);
  drmFreeVersion(retval);

  busid = drmGetBusid(fd);
  printf("busid=%s\n", busid);
  drmFreeBusid(busid);

  assert(!drmGetDevice(fd, &dev));
  printf("pci:%04x:%02x:%02x.%d\n",
	   dev->businfo.pci->domain,
	   dev->businfo.pci->bus,
	   dev->businfo.pci->dev,
	   dev->businfo.pci->func);
  
  drmClose(fd);

  drmDevicePtr devs[16];
  int num = drmGetDevices(devs, 16);
  assert(num >= 0);
  int i;
  for (i = 0; i < num; i++) {
      printf("pci:%04x:%02x:%02x.%d\n",
	   devs[i]->businfo.pci->domain,
	   devs[i]->businfo.pci->bus,
	   devs[i]->businfo.pci->dev,
	   devs[i]->businfo.pci->func);
  }
  
  /*
  struct dirent *dent;
  struct stat sbuf;
  DIR *sysdir;
  
  sysdir = opendir("/dev/dri");
  assert(sysdir);
  while ((dent = readdir(sysdir))) {
    char node[1024];
    snprintf(node, 1024, "/dev/dri/%s", dent->d_name);
    if (stat(node, &sbuf))
      continue;
    printf("path=%s, dev=%x rdev=%x maj=%d min=%d\n", node, sbuf.st_dev, sbuf.st_rdev, major(sbuf.st_rdev), minor(sbuf.st_rdev));
  }
  */
  return 0;
}
















