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
    {
      printf("closing handle\n");
      fflush(stdout);
      RETVAL = dlclose(handle);
    }
    else
    {
      printf("skipping close of handle\n");
      fflush(stdout);
      RETVAL = 0;
    }
  OUTPUT:
    RETVAL
