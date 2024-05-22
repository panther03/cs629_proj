#ifndef BSP_H
#define BSP_H
#include "mmio.h"

static int bspQueue[1024];
static char bspShadowQueue[1024];
static int* bspQueuePtr = bspQueue;
static char* bspShadowQueuePtr = bspShadowQueue;

static void bsp_put(int core, int* source, void* dest, int len) {
    if (len < 1 || len > 16) return; // not allowed to do more than 16 burst
    // head flit
    *(bspShadowQueuePtr++) = 0;
    *(bspQueuePtr++) = (((int)dest)&0x3FFF) | ((len-1) << 14) | ((core&0xF) << 18);
    // body
    for (int i = 0; i < len; i++) {
        *(bspShadowQueuePtr++) = 1;
        *(bspQueuePtr++) = (int)(*(source++));
    }
    *(bspShadowQueuePtr++) = 2;
    *(bspQueuePtr++) = 0;
}

static void bsp_sync() {
    *BSP_MY_SYNC = 1;
    while (!*BSP_ALL_SYNC_START);
    *BSP_ALL_SYNC_START = 0;

    int* bspRdPtr = bspQueue;
    char* bspShadowRdPtr = bspShadowQueue;
    while (bspRdPtr != bspQueuePtr) {
        char type = *(bspShadowRdPtr++);
        int data = *(bspRdPtr++);
        *(ROUTER_SEND_FLIT_H+type) = data;
    }
    bspQueuePtr = bspQueue;
    bspShadowQueuePtr = bspShadowQueue;

    // copy the buffer
    *BSP_MY_SYNC = 0;
    while (!*BSP_ALL_SYNC_END);
    *BSP_ALL_SYNC_END = 0;
}
#endif