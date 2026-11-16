fn main() {
    println!("cargo:rerun-if-changed=linker.ld");
    println!("cargo:rerun-if-changed=src/boot2.S");
    println!("cargo:rerun-if-changed=src/start.S");
}
