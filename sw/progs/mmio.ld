OUTPUT_ARCH( "riscv" )
ENTRY( _start)

/*SECTIONS
{
  . = 0x0;
  .text.init : { *(.text.init) }
  . = ALIGN(0x1000);
  .text : { *(.text) }
  . = ALIGN(0x1000);
  .data : { *(.data) }
  .bss : { *(.bss) }
 _end = .;
}/

/* Define the memory regions */
MEMORY
{
    RAM (rwx) : ORIGIN = 0x00000000, LENGTH = 14K  /* 16KB total, but 2KB reserved */
    RESERVED (rwx) : ORIGIN = 0x00003800, LENGTH = 2K
}

/* Define the sections and their placement in memory */
SECTIONS
{

    /* Place .text section in RAM */
    . = 0x0;
    .text :
    {
        *(.text.init)
        *(.text)
        *(.text.*)
        . = ALIGN(4);          /* Align to 4-byte boundary */
    } > RAM

    /* Place .rodata section in RAM */
    .rodata :
    {
        *(.rodata)             /* All .rodata sections from input files */
        *(.rodata*)            /* All .rodata* sections from input files */
        . = ALIGN(4);          /* Align to 4-byte boundary */
    } > RAM

    /* Place .data section in RAM */
    .data : AT(ADDR(.text) + SIZEOF(.text) + SIZEOF(.rodata))
    {
        *(.data)               /* All .data sections from input files */
        *(.data*)              /* All .data* sections from input files */
        . = ALIGN(4);          /* Align to 4-byte boundary */
    } > RAM

    /* Place .bss section in RAM */
    .bss :
    {
        *(.bss)                /* All .bss sections from input files */
        *(.bss*)               /* All .bss* sections from input files */
        . = ALIGN(4);          /* Align to 4-byte boundary */
        _bss_end = .;
    } > RAM

    /* Ensure no sections go into the RESERVED region unless specified manually */
    /DISCARD/ :
    {
        *(.reserved)           /* Discard any .reserved sections unless specified manually */
    }
}

/* Check the memory usage and fail if it exceeds the allocated space */
ASSERT(_bss_end <= ORIGIN(RAM) + LENGTH(RAM), "Error: Not enough RAM for program.")