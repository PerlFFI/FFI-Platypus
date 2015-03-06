MODULE = FFI::Platypus PACKAGE = FFI::Platypus::ABI

int
verify(abi)
    int abi
  PREINIT:
    ffi_abi ffi_abi;
    ffi_cif ffi_cif;
    ffi_type *args[1];
  CODE:
    /*
     * I had at least one report from (unknown version of) libffi
     * where 999999 was accepted as a legal ABI, and all the other
     * tests passed
     */
    if(abi < FFI_FIRST_ABI || abi > FFI_LAST_ABI)
    {
      RETVAL = 0;
    }
    else
    {
      ffi_abi = abi;
      if(ffi_prep_cif(&ffi_cif, ffi_abi, 0, &ffi_type_void, args) == FFI_OK)
      {
        RETVAL = 1;
      }
      else
      {
        RETVAL = 0;
      }
    }
  OUTPUT:
    RETVAL
