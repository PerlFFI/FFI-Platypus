MODULE = FFI::Platypus PACKAGE = FFI::Platypus::DL

BOOT:
{
  HV *stash;
  stash = gv_stashpv("FFI::Platypus::DL", TRUE);
#ifdef RTLD_LAZY
  newCONSTSUB(stash, "RTLD_PLATYPUS_DEFAULT", newSViv(RTLD_LAZY));
#else
  newCONSTSUB(stash, "RTLD_PLATYPUS_DEFAULT", newSViv(0));
#endif
}

void *
dlopen(filename, flags);
    ffi_pl_string filename
    int flags
  INIT:
    void *ptr;
  CODE:
    ptr = dlopen(filename, flags);
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

void *
dlsym(handle, symbol);
    void *handle
    const char *symbol
  INIT:
    void *ptr;
  CODE:
    ptr = dlsym(handle, symbol);
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
  CODE:
    if(!PL_dirty)
      RETVAL = dlclose(handle);
    else
      RETVAL = 0;
  OUTPUT:
    RETVAL
