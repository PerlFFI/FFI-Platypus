MODULE = FFI::Platypus PACKAGE = FFI::Platypus::DL

int
RTLD_DEFAULT()
  PROTOTYPE: 
  CODE:
#ifdef RTLD_LAZY
    RETVAL = RTLD_LAZY;
#else
    /* For windows, really */
    RETVAL = 0;
#endif
  OUTPUT:
    RETVAL

void *
dlopen(filename, flags);
    ffi_pl_string filename
    int flags
  PROTOTYPE: $$
  CODE:
    void *ptr = dlopen(filename, flags);
    if(ptr == NULL)
    {
      XSRETURN_EMPTY;
    }
    else
    {
      RETVAL = ptr;
    }
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
  CODE:
    void *ptr = dlsym(handle, symbol);
    if(ptr == NULL)
    {
      XSRETURN_EMPTY;
    }
    else
    {
      RETVAL = ptr;
    }
  OUTPUT:
    RETVAL

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
