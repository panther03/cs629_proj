// This is a more complex test that tests that your processor handles JAL
// correctly.
.text
start:
    jal x1, a   // 0x00
a:  jal x2, b   // 0x04
    unimp       // 0x08
c:  jal x4, d   // 0x0C, imm[12] = 1
b:  jal x3, c   // 0x10
    unimp
. = 0x100C
d:  jal x5, e   // imm[11] == 1
    unimp
. = 0x180C
e:  jal x6, f   // imm[10] == 1
    unimp
. = 0x1C0C
f:  unimp
    li a1, 0xf000fff8;
    li a2, 0; 
    sw a2, 0(a1); 