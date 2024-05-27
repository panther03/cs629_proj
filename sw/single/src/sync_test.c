#include "../mmio.h"
#include "../bsp.h"

const int c0_data[] = {1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16};

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
    } else if (cpuid == 1) {
        for (int i = 0; i < 1000; i++) asm volatile ("");
        for (int* scratch_ptr = SCRATCH_START; scratch_ptr < SCRATCH_START + 16; scratch_ptr++) {
            putchar(0x30 + *scratch_ptr);
        }
        puts(c1_string);
    }

}