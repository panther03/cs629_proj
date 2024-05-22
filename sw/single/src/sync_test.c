#include "../mmio.h"


int bspQueue[1024];
char bspShadowQueue[1024];
int* bspQueuePtr = bspQueue;
char* bspShadowQueuePtr = bspShadowQueue;

const int c0_data[] = {1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16};

void bsp_put(int core, int* source, void* dest, int len) {
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

void bsp_sync() {
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

void puts(char* string) {
    while (*string != 0) {
        putchar(*string);
        string++;
    }
}

int main(int a) {
    if (a == 1) { return 1; }
    const char* c0_string = "Core 0: Finished";
    const char* c1_string = "Core 1: Finished";
    int cpuid = *BSP_CPU_ID;
    if (cpuid == 0) {
        //for (int i = 0; i < 10000; i++) asm volatile ("");
        //for (int i = 0; i < 10; i++) {
        bsp_put(1, c0_data, SCRATCH_START, 16);
        //}
    }
    bsp_sync();

    if (cpuid == 0) {
        puts(c0_string);
    } else {
        for (int i = 0; i < 1000; i++) asm volatile ("");
        for (int* scratch_ptr = SCRATCH_START; scratch_ptr < SCRATCH_START + 16; scratch_ptr++) {
            putchar(0x30 + *scratch_ptr);
        }
        puts(c1_string);
    }

}