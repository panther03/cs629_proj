volatile int* DRAM_BASE = (volatile int*)(0xE0000000);
volatile int* UARTLITE_TX = (volatile int*)(0xE4000004);

int main () {
    *DRAM_BASE = 0x69696969;
    if (*DRAM_BASE == 0x69696969) {
        *UARTLITE_TX = (int)'a';
    } else {
        *UARTLITE_TX = (int)'b';
    }
    return 0;
}
