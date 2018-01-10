pub mod rusty
{
  pub extern fn foo () -> (u8, u8)
  {
    (1,2)
  }
}

#[cfg(test)]
mod tests {
    #[test]
    fn it_works() {
        assert_eq!(::rusty::foo(), (1,2));
    }
}
