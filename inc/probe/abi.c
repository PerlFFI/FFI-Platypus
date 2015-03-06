#include "ffi_platypus.h"

int
main(int argc, char *argv[])
{
  ffi_cif cif;
  ffi_type *args[1];
  ffi_abi abi;

  abi = FFI_DEFAULT_ABI;
  
  if(ffi_prep_cif(&cif, abi, 0, &ffi_type_void, args) == FFI_OK)
  {
    return 0;
  }

  return 2;
}
