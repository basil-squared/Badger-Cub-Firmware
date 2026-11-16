.syntax unified
.cpu cortex-m0plus
.thumb

// placed at 0x10000000 by the linker
.section .boot2, "ax"
.align 2
.global _boot2_start 
_boot2_start:
  // configure QSPI pad slew rate and drive strength PADS_QSPI is at 0x4002000
  ldr r3, =0x40020000
  movs r0, #0x41
  str r0, [r3, #0x04]

  // disable SSI to configure the XIP registers
  ldr r3, =0x18000000
  movs r0, #0
  str r0, [r3, #0x08]

  // set baud rate divisor (im gonna set it to 4 so i can push out 31.25mhz @ 125mhz sys_clk)
  movs r0, #4
  str r0, [r3,#0x14]

  // configure the ctrl: put EEPROM into read mode (TMOD = 3 << 8) +  a 32 bit data frame (31 << 16 )
  ldr r0, =(3 << 8) | (31 << 16)
  str r0, [r3,#0x00]

  // configure SPI_CTRLR0 for standard SPI read at 0x03 8 bit cmd, 24 bit addr
  ldr r0, =(0x03 << 24) | (2 << 8) | (6 << 2) | (0 << 0)
  ldr r1, =0x180000f4
  str r0, [r1]

  // me when i read a word
  movs r0, #0
  str r0, [r3, #0x04]

  // reenable SSI to activate the memory mapped XIP at 0x10000000
  movs r0, #1
  str r0, [r3, #0x08]

  // point the processor VTOR to the vector table
  ldr r0, =0x10000100
  ldr r1, =0xe000ed08
  str r0, [r1]

  // load the inital stack pointer from 0x10000100 and jump to the reset vector 0x10000104

  ldmia r0!, {{r1,r2}}
  msr msp, r1
  bx r2
  .ltorg
// pad the remaining space up to byte 252 with 0, leaving 4 bytes for build.rs to do its thing
.org 252
.word 0x00000000

