#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include "ffi_platypus.h"

#ifdef HAVE_DLFCN_H
#include <dlfcn.h>
#endif

typedef const char *ffi_pl_string;

MODULE = FFI::Platypus PACKAGE = FFI::Platypus

MODULE = FFI::Platypus PACKAGE = FFI::Platypus::dl

void *
dlopen(filename);
    ffi_pl_string filename
  CODE:
    RETVAL = dlopen(filename, RTLD_LAZY);
  OUTPUT:
    RETVAL

char *
dlerror();

void *
dlsym(handle, symbol);
    void *handle
    const char *symbol

int
dlclose(handle);
    void *handle
