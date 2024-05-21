#define SIZE 4

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

int arrEquals(int a[SIZE][SIZE], int b[SIZE][SIZE])
{
    for (int i = 0; i < SIZE; i++)
    {
        for (int j = 0; j < SIZE; j++)
        {
            putchar((char)a[i][j]+33);
        //    *((volatile int *)0xF000fff0) = (char)a[i][j]+33;
            if (a[i][j] != b[i][j])
            {
                return 0;
            }
        }
    }
    return 1;
}
int exit(int c);
int a[SIZE][SIZE];
int b[SIZE][SIZE];
int c[SIZE][SIZE];
int expected[SIZE][SIZE];
int main()
{

    // int expected[16][16] = {
    //     {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
    //     {120, 136, 152, 168, 184, 200, 216, 232, 248, 264, 280, 296, 312, 328, 344, 360},
    //     {240, 272, 304, 336, 368, 400, 432, 464, 496, 528, 560, 592, 624, 656, 688, 720},
    //     {360, 408, 456, 504, 552, 600, 648, 696, 744, 792, 840, 888, 936, 984, 1032, 1080},
    //     {480, 544, 608, 672, 736, 800, 864, 928, 992, 1056, 1120, 1184, 1248, 1312, 1376, 1440},
    //     {600, 680, 760, 840, 920, 1000, 1080, 1160, 1240, 1320, 1400, 1480, 1560, 1640, 1720, 1800},
    //     {720, 816, 912, 1008, 1104, 1200, 1296, 1392, 1488, 1584, 1680, 1776, 1872, 1968, 2064, 2160},
    //     {840, 952, 1064, 1176, 1288, 1400, 1512, 1624, 1736, 1848, 1960, 2072, 2184, 2296, 2408, 2520},
    //     {960, 1088, 1216, 1344, 1472, 1600, 1728, 1856, 1984, 2112, 2240, 2368, 2496, 2624, 2752, 2880},
    //     {1080, 1224, 1368, 1512, 1656, 1800, 1944, 2088, 2232, 2376, 2520, 2664, 2808, 2952, 3096, 3240},
    //     {1200, 1360, 1520, 1680, 1840, 2000, 2160, 2320, 2480, 2640, 2800, 2960, 3120, 3280, 3440, 3600},
    //     {1320, 1496, 1672, 1848, 2024, 2200, 2376, 2552, 2728, 2904, 3080, 3256, 3432, 3608, 3784, 3960},
    //     {1440, 1632, 1824, 2016, 2208, 2400, 2592, 2784, 2976, 3168, 3360, 3552, 3744, 3936, 4128, 4320},
    //     {1560, 1768, 1976, 2184, 2392, 2600, 2808, 3016, 3224, 3432, 3640, 3848, 4056, 4264, 4472, 4680},
    //     {1680, 1904, 2128, 2352, 2576, 2800, 3024, 3248, 3472, 3696, 3920, 4144, 4368, 4592, 4816, 5040},
    //     {1800, 2040, 2280, 2520, 2760, 3000, 3240, 3480, 3720, 3960, 4200, 4440, 4680, 4920, 5160, 5400},
    // };

    expected[0][0] = 0;
    expected[0][1] = 0;
    expected[0][2] = 0;
    expected[0][3] = 0;
    // asm volatile("");
    asm volatile("li      t1,12");
    asm volatile("sw      a7,1412(a5)");
    asm volatile("sw      t1,1416(a5)");

    asm volatile("li      t2,13");
    asm volatile("li t3, 8192");
    asm volatile("sw t1,1536(x0)");
    asm volatile("sw t2,1408(x0)");
    // remove cache lines; different tag
    asm volatile("lw t1,1536(t3)");
    asm volatile("lw t2,1408(t3)");

    int thing;
    asm volatile("li     t0, 6969");
    asm volatile("lw     t0, 1416(a5)");
    asm volatile("addi      %0,t0,4" : "=r"(thing));
    if (thing == 6969) {
        exit(1);
    }

    // evil forwarding test
    // both instructions will miss because of earlier cache tomfoolery
    asm volatile("lw t0, 1536(x0)");
    asm volatile("lw t1, 1408(x0)");
    asm volatile("add %0, t0, t1" : "=r"(thing));
    if (thing != 25) {
        exit(1);
    }

    expected[1][0] = 6;
    expected[1][1] = 10;
    expected[1][2] = 14;
    expected[1][3] = 18;

    expected[2][0] = 12;
    expected[2][1] = 20;
    expected[2][2] = 28;
    expected[2][3] = 36;

    expected[3][0] = 18;
    expected[3][1] = 30;
    expected[3][2] = 42;
    expected[3][3] = 54;


/*
    expected[0][0] = 0;
    expected[0][1] = 0;
    expected[0][2] = 0;

    expected[1][0] = 3;
    expected[1][1] = 6;
    expected[1][2] = 9;

    expected[2][0] = 6;
    expected[2][1] = 12;
    expected[2][2] = 18;*/

    /*for (int i = 0; i < SIZE; i++)
    {
        for (int j = 0; j < SIZE; j++)
        {
            a[i][j] = i;
            b[i][j] = i + j;
            putchar('a');
        }
    }*/
    a[0][0] = 0;
    a[0][1] = 0;
    a[0][2] = 0;
    a[0][3] = 0;
    a[1][0] = 1;
    a[1][1] = 1;
    a[1][2] = 1;
    a[1][3] = 1;
    a[2][0] = 2;
    a[2][1] = 2;
    a[2][2] = 2;
    a[2][3] = 2;
    a[3][0] = 3;
    a[3][1] = 3;
    a[3][2] = 3;
    a[3][3] = 3;

    b[0][0] = 0;
    b[0][1] = 1;
    b[0][2] = 2;
    b[0][3] = 3;
    b[1][0] = 1;
    b[1][1] = 2;
    b[1][2] = 3;
    b[1][3] = 4;
    b[2][0] = 2;
    b[2][1] = 3;
    b[2][2] = 4;
    b[2][3] = 5;
    b[3][0] = 3;
    b[3][1] = 4;
    b[3][2] = 5;
    b[3][3] = 6;

    int sum;
    putchar('a');
    for (int i = 0; i < SIZE; i++)
    {
        for (int j = 0; j < SIZE; j++)
        {
            sum = 0;
            for (int k = 0; k < SIZE; k++)
            {
                sum += multiply(a[i][k], b[k][j]);
            }
            putchar((char)sum+33);
            c[i][j] = sum;
        }
    }

    if (arrEquals(expected, c))
    {
        exit(0);
    }
    else
    {
        exit(1);
    }
    return 0;
}
