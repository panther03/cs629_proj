#include "../mmio.h"
#include "../bsp.h"

const int c0_v1data[] = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 91, 92, 93, 94, 95, 96, 97, 98, 99, 100, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 111, 112, 113, 114, 115, 116, 117, 118, 119, 120, 121, 122, 123, 124, 125, 126, 127, 128};
// const int c0_v1data[] = {1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0};
// const int zeros[] = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0};
const int c0_v2data[] = {1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1};

void puts(char *string)
{
    while (*string != 0)
    {
        putchar(*string);
        string++;
    }
}

int multiply(int x, int y)
{
    int ret = 0;
    for (int i = 0; i < 32; i++)
    {
        if (((y >> i) & 1) == 1)
        {
            ret += (x << i);
        }
    }
    return ret;
}

int main(int a)
{
    // if (a == 1) { return 1; }
    const char *c0_string = "Core 0: Finished";
    const char *c1_string = "Core 1: Finished";
    const char *c2_string = "Core 2: Finished";
    const char *c3_string = "Core 3: Finished";
    const char *c4_string = "Core 4: Finished";
    const char *c5_string = "Result is: ";
    const char *c6_string = "True";
    const char *c7_string = "False";
    const char *c10_string = "c0_v1data true";

    int cpuid = *BSP_CPU_ID;

    if (cpuid == 0)
    {
        for (int i = 1; i < 9; i = i + 1)
        {
            bsp_put(i, c0_v1data + ((i - 1) << 4), SCRATCH_START, 16); // first put the v1 from SCRATCH_START then put the v2 after 4 address.
        }
    }

    bsp_sync();

    if (cpuid == 0)
    {
        for (int i = 1; i < 9; i = i + 1)
        {
            bsp_put(i, c0_v2data + ((i - 1) << 4), SCRATCH_START + 16, 16);
        }
    }

    bsp_sync();

    if (cpuid != 0)
    {

        // for (int i = 0; i < 1000; i++) asm volatile ("");    	    								// all the cpus apart from 0 start calculation
        int sum = 0;
        for (int *scratch_ptr = SCRATCH_START; scratch_ptr < SCRATCH_START + 16; scratch_ptr++)
        { // results is overwritten to (SCRATCH_START+8)
            sum = sum + multiply((*scratch_ptr), (*(scratch_ptr + 16)));
            // bsp_put(0, scratch_ptr, SCRATCH_START+cpuid, 1);
            // putchar(0x30 + *scratch_ptr);
        }
        *SCRATCH_START = sum;
        bsp_put(0, SCRATCH_START, SCRATCH_START + cpuid, 1); // bsp_put targets the same core but different address as according to their ID from SCRATCH_START
    }

    bsp_sync(); // another sync since we calle bsp_put

    if (cpuid == 0)
    {

        // for (int i = 0; i < 1000; i++) asm volatile ("");  						//P0 sums the results
        *SCRATCH_START = 0;
        int sum = 0;
        for (int *scratch_ptr = SCRATCH_START + 1; scratch_ptr < SCRATCH_START + 9; scratch_ptr++)
            sum = sum + *(scratch_ptr);
        *SCRATCH_START = sum;
        puts(c5_string);
        if (sum == 8256)
        {
            puts(c6_string);
            exit(0);
        }
        else
        {
            puts(c7_string);
            exit(1);
        }
    }
}
