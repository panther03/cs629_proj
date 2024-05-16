#ifndef MMIO_H
#define MMIO_H

extern volatile int* BSP_MY_SYNC;
extern volatile int* BSP_ALL_SYNC_START;
extern volatile int* BSP_ALL_SYNC_END;
extern volatile int* BSP_CPU_ID;
extern volatile int* ROUTER_SEND_FLIT_N;
extern volatile int* ROUTER_SEND_FLIT_H;
extern volatile int* ROUTER_SEND_FLIT_T;
extern volatile int* SCRATCH_START;

int putchar(int c);
int exit(int c);

#endif
