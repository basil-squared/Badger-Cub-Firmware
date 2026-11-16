use std::env;
use std::fs;

/// rp20404 s masek rom im tired
fn rp2040_crc32(data: &[u8]) -> u32 {
    let mut crc: u32 = 0xFFFF_FFFF;
    for &byte in data {
        crc ^= (byte as u32) << 24;
        for _ in 0..8 {
            if (crc & 0x8000_0000) != 0 {
                crc = (crc << 1) ^ 0x04C1_1DB7;
            } else {
                crc <<= 1;
            }
        }
    }
    crc
}

fn main() {
    let elf_path = env::args().nth(1).expect("usage: patch_boot2 <path-to-elf>");
    let mut elf = fs::read(&elf_path).expect("failed to read ELF file");

    // parse 32-bit ELF program headers
    assert_eq!(&elf[0..4], b"\x7fELF", "Not a valid ELF file");
    let e_phoff = u32::from_le_bytes(elf[28..32].try_into().unwrap()) as usize;
    let e_phentsize = u16::from_le_bytes(elf[42..44].try_into().unwrap()) as usize;
    let e_phnum = u16::from_le_bytes(elf[44..46].try_into().unwrap()) as usize;

    let mut patched = false;
    for i in 0..e_phnum {
        let off = e_phoff + i * e_phentsize;
        let p_type = u32::from_le_bytes(elf[off..off + 4].try_into().unwrap());
        let p_offset = u32::from_le_bytes(elf[off + 4..off + 8].try_into().unwrap()) as usize;
        let p_paddr = u32::from_le_bytes(elf[off + 12..off + 16].try_into().unwrap());
        let p_filesz = u32::from_le_bytes(elf[off + 16..off + 20].try_into().unwrap()) as usize;

        if p_type == 1 && p_paddr == 0x1000_0000 && p_filesz >= 256 {
            let crc = rp2040_crc32(&elf[p_offset..p_offset + 252]);
            elf[p_offset + 252..p_offset + 256].copy_from_slice(&crc.to_le_bytes());
            fs::write(&elf_path, &elf).expect("Failed to write patched ELF");
            println!("patched .boot2 offset {:#x} with CRC32 = {:#010x}", p_offset, crc);
            patched = true;
            break;
        }
    }

    assert!(patched, "Could not find PT_LOAD seg");
}
