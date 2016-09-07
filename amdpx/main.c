#include <X11/Xlib.h>
#include <X11/Xlibint.h>
#include <stdio.h>
#include <assert.h>

#define AMDPX_EXTENSION_NAME "AMDPX"
#define X_AMDPXCanFlip 0

typedef struct {
    CARD8 reqType;
    CARD8 amdpxReqType;
    CARD16 length B16;
    CARD32 window B32;
} xAMDPXCanFlipReq;

typedef struct {
    BYTE type;
    BYTE pad1;
    CARD16  sequenceNumber B16;
    CARD32  length B32;
    CARD32  canFlip B32;
    CARD32  pad2 B32;
    CARD32  pad3 B32;
    CARD32  pad4 B32;
    CARD32  pad5 B32;
    CARD32  pad6 B32;
} xAMDPXCanFlipReply;

#define sz_xAMDPXCanFlipReq sizeof(xAMDPXCanFlipReq)
#define sz_xAMDPXCanFlipReply sizeof(xAMDPXCanFlipReply)

void canflip(Display *dpy, Window window, int opcode)
{
	xAMDPXCanFlipReq *req;
	xAMDPXCanFlipReply rep;

	LockDisplay(dpy);
	GetReq(AMDPXCanFlip, req);
	req->reqType = opcode;
	req->amdpxReqType = X_AMDPXCanFlip;
	req->window = window;
	if (!_XReply(dpy, (xReply *)&rep, 0, xTrue)) {
		printf("canflip: error or fail\n");
		UnlockDisplay(dpy);
		SyncHandle();
		return;
	}

	printf("canflip: reply s=%u c=%u\n", rep.sequenceNumber, rep.canFlip);
	UnlockDisplay(dpy);
	SyncHandle();
}


int main(int argc, char **argv)
{
    Display *display;
    assert((display = XOpenDisplay(NULL)) != NULL);

	int opcode, event, error;
	assert(XQueryExtension(display, "AMDPX", &opcode, &event, &error));

    int screen = DefaultScreen(display);
    Window root = DefaultRootWindow(display);
    Window window =  XCreateWindow(display, root, 0, 0, 500, 500, 0,
			 DefaultDepth(display, screen), InputOutput,
			 DefaultVisual(display, screen), 
			 0, NULL);
    XMapWindow(display, window);
    XFlush(display);

	canflip(display, window, opcode);
    return 0;
}
