volatile int* SPART_BASE = (volatile int*)(0xE0F00000);

int main () {
    const char* string = "helloworld\n";
    *(SPART_BASE+3) = 1; 
    for (char* c = string; c < string + 11; c++) {
        while ((*(SPART_BASE+2) & 0xF0) <= 0x40) asm volatile("");
        *SPART_BASE = (int)*c;
    }
    return 0;
}