/* defining the actual memory here, gonna be excessively commenting because holy smokes is this new to me */
MEMORY {
  /* RP2040 aligns starting at 0x10000000, this lets it do the thing where it powers on, copies a tiny 256b of data and then executes it*/
  BOOT2 : ORIGIN = 0x10000000, LENGTH = 0x100 
  /* This is where all of the startup code and stuff is gonna run, along with any other constants n stuff */
  FLASH : ORIGIN = 0x10000100, LENGTH = 512K - 0x100
  /* im gonna use the rest of the 2M flash i have for the images, these are 1 bit bmps so they're itty bitty */
  SLOTS : ORIGIN = 0x10080000, LENGTH = 1536K
  /* this goes to the .... you guessed it, the ram of the RP2040 */
  RAM   : ORIGIN = 0x20000000, LENGTH = 264K
}

/* sending out the actual stack pointer here */
_stack_top = ORIGIN(RAM) + LENGTH(RAM);
/* starting at the top of the ram gives me max chance before i start hitting anything at the bottom. hopefully i can protect against that, tho */


/* and now i map actual code and data to these sections. observe my wizardry */
SECTIONS {
  .boot2 ORIGIN(BOOT2) : {
    KEEP(*(.boot2));

  } > BOOT2
  .text ORIGIN(FLASH) : {
    KEEP(*(.vector_table));
    *(.text .text.*);
    *(.rodata .rodata.*);
    . = ALIGN(4);
  } > FLASH
  _sidata = LOADADDR(.data);
  .data : ALIGN(4) {
    _sdata = .;
    *(.data .data.*);
    . = ALIGN(4);
    _edata = .;

  } > RAM AT > FLASH
  .bss : ALIGN(4) {
    _sbss = .;
    *(.bss .bss.* COMMON);
    . = ALIGN(4);
    _ebss = .;


  } > RAM

  /DISCARD/ : {
    *(.ARM.exidx* .ARM.extab);
}
}
