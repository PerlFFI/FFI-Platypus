#include "ffi_platypus.h"

unsigned char
my_foo(void)
{
  return 0xaa;
}

int
main(int argc, char *argv[])
{
  ffi_cif cif;
  ffi_type *args[1];
  void *values[1];
  unsigned char bytes[4] = { 0x00, 0x00, 0x00, 0x00 };
  
  if(ffi_prep_cif(&cif, FFI_DEFAULT_ABI, 0, &ffi_type_uint8, args) ==FFI_OK)
  {
    ffi_call(&cif, (void *) my_foo, &bytes, values);
    if(bytes[3] == 0xaa)
    {
      return 0;
    }
  }

  return 2;
}
