#include "../mmio.h"

int main(int s) {
  if (s == 1) return 0;

  *SCRATCH_START = 42;
  if (*SCRATCH_START == 42) {
    putchar('a');
  } else {
    putchar('b');
  }

  *BSP_MY_SYNC = 1;

  if (*BSP_MY_SYNC) {
    putchar('y');
    putchar('a');
    putchar('y');
    return 0;
  } else return 1;
}