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
new(class, type)
    const char *class;
    const char *type;
  PREINIT:
    ffi_pl_type *self;
  CODE:
    Newx(self, 1, ffi_pl_type);
    if(!strcmp(type, "string"))
    {
      self->ffi_type = &ffi_type_pointer;
      self->platypus_type = FFI_PL_STRING;
    }
    else
    {
      self->platypus_type = FFI_PL_FFI;
      if(!strcmp(type, "void"))
      { self->ffi_type = &ffi_type_void; }
      else if(!strcmp(type, "uint8"))
      { self->ffi_type = &ffi_type_uint8; }
      else if(!strcmp(type, "sint8"))
      { self->ffi_type = &ffi_type_sint8; }
      else if(!strcmp(type, "uint16"))
      { self->ffi_type = &ffi_type_uint16; }
      else if(!strcmp(type, "sint16"))
      { self->ffi_type = &ffi_type_sint16; }
      else if(!strcmp(type, "uint32"))
      { self->ffi_type = &ffi_type_uint32; }
      else if(!strcmp(type, "sint32"))
      { self->ffi_type = &ffi_type_sint32; }
      else if(!strcmp(type, "uint64"))
      { self->ffi_type = &ffi_type_uint64; }
      else if(!strcmp(type, "sint64"))
      { self->ffi_type = &ffi_type_sint64; }
      else if(!strcmp(type, "float"))
      { self->ffi_type = &ffi_type_float; }
      else if(!strcmp(type, "double"))
      { self->ffi_type = &ffi_type_double; }
      else if(!strcmp(type, "longdouble"))
      { self->ffi_type = &ffi_type_longdouble; }
      else if(!strcmp(type, "pointer"))
      { self->ffi_type = &ffi_type_pointer; }
      else
      {
        Safefree(self);
        croak("unknown platypus/ffi type: %s", type);
      }
    }
    self->arg_ffi2pl = NULL;
    self->arg_pl2ffi = NULL;
    self->ret_ffi2pl = NULL;
    self->ret_pl2ffi = NULL;
    RETVAL = self;
  OUTPUT:
    RETVAL

ffi_pl_string
ffi_type(self)
    ffi_pl_type *self;
  CODE:
    switch(self->ffi_type->type)
    {
      case FFI_TYPE_VOID:
        RETVAL = "void";
        break;
      case FFI_TYPE_FLOAT:
        RETVAL = "float";
        break;
      case FFI_TYPE_DOUBLE:
        RETVAL = "double";
        break;
      case FFI_TYPE_LONGDOUBLE:
        RETVAL = "longdouble";
        break;
      case FFI_TYPE_UINT8:
        RETVAL = "uint8";
        break;
      case FFI_TYPE_SINT8:
        RETVAL = "sint8";
        break;
      case FFI_TYPE_UINT16:
        RETVAL = "uint16";
        break;
      case FFI_TYPE_SINT16:
        RETVAL = "sint16";
        break;
      case FFI_TYPE_UINT32:
        RETVAL = "uint32";
        break;
      case FFI_TYPE_SINT32:
        RETVAL = "sint32";
        break;
      case FFI_TYPE_UINT64:
        RETVAL = "uint64";
        break;
      case FFI_TYPE_SINT64:
        RETVAL = "sint64";
        break;
      case FFI_TYPE_POINTER:
        RETVAL = "pointer";
        break;
      default:
        RETVAL = NULL;
        break;
    }
  OUTPUT:
    RETVAL

void
DESTROY(self)
    ffi_pl_type *self;
  CODE:
    Safefree(self);
