#include "../mmio.h"
#include "../bsp.h"

const int c0_v1data[] = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 91, 92, 93, 94, 95, 96, 97, 98, 99, 100, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 111, 112, 113, 114, 115, 116, 117, 118, 119, 120, 121, 122, 123, 124, 125, 126, 127, 128};
const int c0_v2data[] = {1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1};

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

void puts(char *string)
{
    while (*string != 0)
    {
        putchar(*string);
        string++;
    }
}

void putint(int a)
{
    int lut[16] = {'0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'a', 'b', 'c', 'd', 'e', 'f'};
    for (int i = 1; i < 9; i++)
    {
        putchar((lut[0xF & (a >> (32 - (i << 2)))]));
    }
    putchar('\n');
}

int main(int a)
{
    // if (a == 1) { return 1; }
    const char *c5_string = "Result is: ";
    const char *c6_string = "True\n";
    const char *c7_string = "False\n";
    int sum = 0;
    volatile int *v1_ptr = c0_v1data;
    volatile int *v2_ptr = c0_v2data;
    for (int i = 0; i < 128; i++)
    { // results is overwritten to (SCRATCH_START+8)
        sum += multiply(*(v1_ptr++), *(v2_ptr++));
    }
    puts(c5_string);
    // putint(sum);					// print the final result, for /CPU0 this is the whole sum
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
