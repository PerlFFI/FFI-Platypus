MODULE = FFI::Platypus PACKAGE = FFI::Platypus::dl

void *
dlopen(filename);
    ffi_pl_string filename
  PROTOTYPE: $
  CODE:
    RETVAL = dlopen(filename, RTLD_LAZY);
  OUTPUT:
    RETVAL

const char *
dlerror();
  PROTOTYPE: 

void *
dlsym(handle, symbol);
    void *handle
    const char *symbol
  PROTOTYPE: $$

int
dlclose(handle);
    void *handle
  PROTOTYPE: $
  CODE:
    if(!PL_dirty)
      RETVAL = dlclose(handle);
    else
      RETVAL = 0;
  OUTPUT:
    RETVAL
