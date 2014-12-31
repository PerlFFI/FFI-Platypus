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

MODULE = FFI::Platypus PACKAGE = FFI::Platypus::type

ffi_pl_type *
new(class)
    const char *class;
  PREINIT:
    ffi_pl_type *self;
  CODE:
    Newx(self, 1, ffi_pl_type);
    self->ffi_type = NULL;
    self->platypus_type = FFI_PL_FFI;
    self->arg_ffi2pl = NULL;
    self->arg_pl2ffi = NULL;
    self->ret_ffi2pl = NULL;
    self->ret_pl2ffi = NULL;
    RETVAL = self;
  OUTPUT:
    RETVAL

void
DESTROY(self)
    ffi_pl_type *self;
  CODE:
    Safefree(self);
