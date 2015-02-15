#include <ffi.h>
#include <stdio.h>

/*
 * experiment with libffi and 8 and 16 bit integer
 * return types
 */

unsigned char
my_foo(void)
{
  return 0xaa;
}

unsigned short
my_bar(void)
{
  return 0xbeef;
}

int
main(int argc, char *argv[])
{
  ffi_cif  ffi_cif;
  ffi_type *args[1];
  int i;
  void *values[1];
  unsigned char  bytes[4] = { 0x00, 0x00, 0x00, 0x00 };
  unsigned short shorts[2] = { 0x0000, 0x0000 };

  if(ffi_prep_cif(&ffi_cif, FFI_DEFAULT_ABI, 0, &ffi_type_uint8, args) == FFI_OK)
  {
    ffi_call(&ffi_cif, my_foo, &bytes, values);
    for(i=0; i<4; i++)
    {
      printf("bytes[%d] = %02x\n", i, bytes[i]);
    }
  }

  if(ffi_prep_cif(&ffi_cif, FFI_DEFAULT_ABI, 0, &ffi_type_uint16, args) == FFI_OK)
  {
    ffi_call(&ffi_cif, my_bar, &shorts, values);
    for(i=0; i<2; i++)
    {
      printf("shorts[%d] = %04x\n", i, shorts[i]);
    }
  }

  return 0;
}
