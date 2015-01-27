// compile with: rustc --crate-type dylib string.rs

#[no_mangle]
pub extern "C" fn hello_rust() -> *const u8 {
  "Hello, world\n\0".as_ptr()
}
