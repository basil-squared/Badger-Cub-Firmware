.syntax unified
.cpu cortex-m0plus
.thumb

.section .vector_table, "a"
.align 2
.global __VECTOR_TABLE
__VECTOR_TABLE:
  .word _stack_top
  .word _reset_handler
  .word _default_handler
  .word _default_handler

.section .text._reset_handler, "ax"
.thumb_func
.global _reset_handler
_reset_handler:
/* flash into sram  */
  ldr r0, =_sdata
  ldr r1, =_edata
  ldr r2, =_sidata
1:
  cmp r0, r1 /* are we at _edata yet */
  bhs 2f /* branch if higher or same to label 2 */
  ldmia r2!, {{r3}} /* load 32 bit word from r2 into r3, then add 4 to r2 */
  stmia r0!, {{r3}} /* store the word from r3 into r0, then add 4 to r0 */
  b 1b /* back to label 1 */
2:
  /* fill .bss with zeroes */
  ldr r0, =_sbss
  ldr r1, =_ebss
  movs r2, #0
3:
  cmp r0, r1
  bhs 4f
  stmia r0!, {{r2}}
  b 3b
4:
  bl kmain /* this part is where we actually go to rust's kmain func */

/* send the chip into hell if it fails or returns from kmain */
_default_handler:
  b _default_handler
