#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include "ffi_platypus.h"

#ifndef HAVE_IV_IS_64
#include "perl_math_int64.h"
#endif

XS(ffi_pl_sub_call)
{
  ffi_pl_function *self;
  char *buffer;
  size_t buffer_size;
  int i,n;
  SV *arg;
  ffi_arg result;
  ffi_pl_arguments *arguments;
  
  dVAR; dXSARGS;
  
  self = (ffi_pl_function*) CvXSUBANY(cv).any_ptr;

#define EXTRA_ARGS 0
#include "ffi_platypus_call.h"
}

MODULE = FFI::Platypus PACKAGE = FFI::Platypus

BOOT:
#ifndef HAVE_IV_IS_64
    PERL_MATH_INT64_LOAD_OR_CROAK;
#endif

MODULE = FFI::Platypus PACKAGE = FFI::Platypus::dl

void *
dlopen(filename);
    ffi_pl_string filename
  CODE:
    RETVAL = dlopen(filename, RTLD_LAZY);
  OUTPUT:
    RETVAL

const char *
dlerror();

void *
dlsym(handle, symbol);
    void *handle
    const char *symbol

int
dlclose(handle);
    void *handle

MODULE = FFI::Platypus PACKAGE = FFI::Platypus::Type

ffi_pl_type *
_new(class, type, platypus_type, array_size)
    const char *class
    const char *type
    const char *platypus_type
    size_t array_size
  PREINIT:
    ffi_pl_type *self;
  CODE:
    self = NULL;
    if(!strcmp(platypus_type, "string"))
    {
      Newx(self, 1, ffi_pl_type);
      self->ffi_type = NULL;
      self->platypus_type = FFI_PL_STRING;
    }
    else if(!strcmp(platypus_type, "ffi"))
    {
      Newx(self, 1, ffi_pl_type);
      self->ffi_type = NULL;
      self->platypus_type = FFI_PL_FFI;
    }
    else if(!strcmp(platypus_type, "pointer"))
    {
      Newx(self, 1, ffi_pl_type);
      self->ffi_type = NULL;
      self->platypus_type = FFI_PL_POINTER;
    }
    else if(!strcmp(platypus_type, "array"))
    {
      char *buffer;
      Newx(buffer, sizeof(ffi_pl_type) + sizeof(ffi_pl_type_extra), char);
      self = (ffi_pl_type*) buffer;
      self->ffi_type = NULL;
      self->platypus_type = FFI_PL_ARRAY;
      self->extra[0].array.element_count = array_size;
    }
    else
    {
      croak("unknown ffi/platypus type: %s/%s", type, platypus_type);
    }

    if(self != NULL && self->ffi_type == NULL)
    {
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
        self = NULL;
        croak("unknown ffi/platypus type: %s/%s", type, platypus_type);
      }
    }

    RETVAL = self;
  OUTPUT:
    RETVAL

ffi_pl_string
ffi_type(self)
    ffi_pl_type *self
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

size_t
array_size(self)
    ffi_pl_type *self
  CODE:
    if(self->platypus_type == FFI_PL_ARRAY)
      RETVAL = self->extra[0].array.element_count;
    else
      RETVAL = 0;
  OUTPUT:
    RETVAL

void
DESTROY(self)
    ffi_pl_type *self
  CODE:
    Safefree(self);

MODULE = FFI::Platypus PACKAGE = FFI::Platypus::Function

ffi_pl_function *
new(class, platypus, address, return_type, ...)
    const char *class
    SV *platypus
    void *address
    ffi_pl_type *return_type
  PREINIT:
    ffi_pl_function *self;
    ffi_status status;
    int i;
    SV* arg;
    ffi_type **signature;
    void *buffer;
    ffi_type *ffi_return_type;
  CODE:
  
    for(i=0; i<(items-4); i++)
    {
      arg = ST(i+4);
      if(!(sv_isobject(arg) && sv_derived_from(arg, "FFI::Platypus::Type")))
      {
        croak("non-type parameter passed in as type");
      }
    }
  
    Newx(buffer, (sizeof(ffi_pl_function) + sizeof(ffi_pl_type*)*(items-4)), char);
    self = (ffi_pl_function*)buffer;
    Newx(signature, items-4, ffi_type*);
    
    self->address = address;
    self->return_type = return_type;
    
    if(self->return_type->platypus_type == FFI_PL_FFI)
    {
      ffi_return_type = self->return_type->ffi_type;
    }
    else
    {
      ffi_return_type = &ffi_type_pointer;
    }
    
    for(i=0; i<(items-4); i++)
    {
      arg = ST(i+4);
      self->argument_types[i] = INT2PTR(ffi_pl_type*, SvIV((SV*) SvRV(arg)));
      if(self->argument_types[i]->platypus_type == FFI_PL_FFI)
      {
        signature[i] = self->argument_types[i]->ffi_type;
      }
      else
      {
        signature[i] = &ffi_type_pointer;
      }
    }
    
    status = ffi_prep_cif(
      &self->ffi_cif,            /* ffi_cif     | */
      FFI_DEFAULT_ABI,           /* ffi_abi     | */
      items-4,                   /* int         | argument count */
      ffi_return_type,           /* ffi_type *  | return type */
      signature                  /* ffi_type ** | argument types */
    );
    
    if(status != FFI_OK)
    {
      Safefree(self);
      Safefree(signature);
      if(status == FFI_BAD_TYPEDEF)
        croak("bad typedef");
      else if(status == FFI_BAD_ABI)
        croak("bad abi");
      else
        croak("unknown error with ffi_prep_cif");
    }
    
    self->sv = SvREFCNT_inc(platypus);

    RETVAL = self;
  OUTPUT:
    RETVAL

void
call(self, ...)
    ffi_pl_function *self
  PREINIT:
    char *buffer;
    size_t buffer_size;
    int i, n;
    SV *arg;
    ffi_arg result;
    ffi_pl_arguments *arguments;
  CODE:
#define EXTRA_ARGS 1
#include "ffi_platypus_call.h"

void
attach(self, perl_name, path_name)
    SV *self
    const char *perl_name
    ffi_pl_string path_name
  PREINIT:
    CV* cv;
  CODE:
    if(!(sv_isobject(self) && sv_derived_from(self, "FFI::Platypus::Function")))
      croak(aTHX_ "self is not of type FFI::Platypus::Function");

    if(path_name == NULL)
      path_name = "unknown";

    cv = newXS(perl_name, ffi_pl_sub_call, path_name);
    CvXSUBANY(cv).any_ptr = (void *) INT2PTR(ffi_pl_function*, SvIV((SV*) SvRV(self)));
    /*
     * No coresponding decrement !!
     * once attached, you can never free the function object, or the FFI::Platypus
     * it was created from.
     */
    SvREFCNT_inc(self);

void
DESTROY(self)
    ffi_pl_function *self
  CODE:
    SvREFCNT_dec(self->sv);
    Safefree(self->ffi_cif.arg_types);
    Safefree(self);

