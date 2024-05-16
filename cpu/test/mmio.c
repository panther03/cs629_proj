// Dangerous, we should add volatile
volatile int* PUT_ADDR = (int *)0xF000fff0;
volatile int* FINISH_ADDR = (int *)0xF000fff8;

volatile int* BSP_MY_SYNC = (int *)0xFD000000;
volatile int* BSP_ALL_SYNC_START = (int *)0xFD000004;
volatile int* BSP_ALL_SYNC_END = (int *)0xFD000008;

volatile int* ROUTER_SEND_FLIT_N = (int *)0xFE000000;
volatile int* ROUTER_SEND_FLIT_H = (int *)0xFE000004;
volatile int* ROUTER_SEND_FLIT_T = (int *)0xFE000008;

volatile int* SCRATCH_START = (int *)0xFF000000;

int putchar(int c) {
  *PUT_ADDR = c;
  return c;
}

int exit(int c) {
  *FINISH_ADDR = c;
  return c;
}
