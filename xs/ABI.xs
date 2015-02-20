MODULE = FFI::Platypus PACKAGE = FFI::Platypus::ABI

int
verify(abi)
    int abi
  PREINIT:
    ffi_abi ffi_abi;
    ffi_cif ffi_cif;
    ffi_type *args[0];
  CODE:
    ffi_abi = abi;
    if(ffi_prep_cif(&ffi_cif, ffi_abi, 0, &ffi_type_void, args) == FFI_OK)
    {
      RETVAL = 1;
    }
    else
    {
      RETVAL = 0;
    }
  OUTPUT:
    RETVAL
