pub mod rusty
{
  pub extern fn foo () -> (u8, u8)
  {
    (1,2)
  }
}

#[no_mangle]
pub extern "C" fn i32_sum(a:i32,b:i32) -> i32
{ a + b }

#[cfg(test)]
mod tests {

    #[test]
    fn it_works() {
        assert_eq!(::rusty::foo(), (1,2));
    }

    #[test]
    fn i32_sum_works() {
        assert_eq!(::i32_sum(1,2), 3);
        assert_eq!(::i32_sum(3,4), 7);
        assert_eq!(::i32_sum(-1,4), 3);
    }
}

