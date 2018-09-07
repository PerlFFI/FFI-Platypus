MODULE = FFI::Platypus PACKAGE = FFI::Platypus::DL

BOOT:
{
  HV *stash;
  stash = gv_stashpv("FFI::Platypus::DL", TRUE);
#ifdef RTLD_LAZY
  newCONSTSUB(stash, "RTLD_PLATYPUS_DEFAULT", newSViv(RTLD_LAZY));
  newCONSTSUB(stash, "RTLD_LAZY", newSViv(RTLD_LAZY));
#else
  newCONSTSUB(stash, "RTLD_PLATYPUS_DEFAULT", newSViv(0));
#endif
#ifdef RTLD_NOW
  newCONSTSUB(stash, "RTLD_NOW", newSViv(RTLD_NOW));
#endif
#ifdef RTLD_GLOBAL
  newCONSTSUB(stash, "RTLD_GLOBAL", newSViv(RTLD_GLOBAL));
#endif
#ifdef RTLD_LOCAL
  newCONSTSUB(stash, "RTLD_LOCAL", newSViv(RTLD_LOCAL));
#endif
#ifdef RTLD_NODELETE
  newCONSTSUB(stash, "RTLD_NODELETE", newSViv(RTLD_NODELETE));
#endif
#ifdef RTLD_NOLOAD
  newCONSTSUB(stash, "RTLD_NOLOAD", newSViv(RTLD_NOLOAD));
#endif
#ifdef RTLD_DEEPBIND
  newCONSTSUB(stash, "RTLD_DEEPBIND", newSViv(RTLD_DEEPBIND));
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
