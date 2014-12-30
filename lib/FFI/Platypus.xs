#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include <ffi.h>
#include <dlfcn.h>

MODULE = FFI::Platypus PACKAGE = FFI::Platypus

MODULE = FFI::Platypus PACKAGE = FFI::Platypus::dl

void *
dlopen(filename);
    const char *filename
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
