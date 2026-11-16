#![no_std]
#![no_main]

use core::arch::global_asm;
use core::panic::PanicInfo;
use core::ptr::{read_volatile, write_volatile};

// get vector table and _reset_handler into the bin 
global_asm!(include_str!("boot2.S"));
global_asm!(include_str!("start.S"));


// peripheral reg addresses that i ripped straight from the datasheet
const RESETS_BASE: u32 = 0x4000_c000;
const RESETS_RESET: *mut u32 = RESETS_BASE as *mut u32; // peripheral reset ctl at offset 0x00
const RESETS_RESET_DONE: *const u32 = (RESETS_BASE + 0x08) as *const u32; // peripheral cmp status..
// at 0x08
const IO_BANK0_BASE: u32 = 0x4001_4000;
const GPIO25_CTRL: *mut u32 = (IO_BANK0_BASE + 0xcc) as *mut u32; // gpio25 pin control


const SIO_BASE: u32 = 0xd000_0000;
const SIO_GPIO_OUT_XOR: *mut u32 = (SIO_BASE + 0x1c) as *mut u32; // atom pin out toggle
const SIO_GPIO_OE_SET: *mut u32 = (SIO_BASE + 0x24) as *mut u32 ; // atom pin out enable


#[unsafe(no_mangle)]
pub extern "C" fn kmain() -> ! {
    unsafe {
        // taking IO_BANK0 and PADS_BANK0 out of hardware reset
        let reset_mask: u32 = (1 << 5) | (1 << 8);
        let current = read_volatile(RESETS_RESET);
        write_volatile(RESETS_RESET, current & !reset_mask);

        // spin around until i know that both blocks are RTG
        while (read_volatile(RESETS_RESET_DONE) & reset_mask) != reset_mask {
            core::hint::spin_loop();
        }

        // route gpio25 to the SIO controller
        write_volatile(GPIO25_CTRL, 5);

        // enabling gpio25 as an output by setting bit 25 in OE_SET
        write_volatile(SIO_GPIO_OE_SET, 1 << 25);

        // now this pin gets to blink forever and ever (basically)
        loop {
            write_volatile(SIO_GPIO_OUT_XOR, 1<<25);
            for _ in 0..800_000 {
                core::hint::spin_loop();
            }
        }
    }
}
#[panic_handler]
fn panic(_info: &PanicInfo) -> ! {
    loop {
        core::hint::spin_loop();
    }
}
