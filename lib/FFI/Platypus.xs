#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include "ffi_platypus.h"

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
    const char *class
    const char *type
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

void
DESTROY(self)
    ffi_pl_type *self
  CODE:
    Safefree(self);

MODULE = FFI::Platypus PACKAGE = FFI::Platypus::function

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
  CODE:
  
    for(i=0; i<(items-4); i++)
    {
      arg = ST(i+4);
      if(!(sv_isobject(arg) && sv_derived_from(arg, "FFI::Platypus::type")))
      {
        croak("non-type parameter passed in as type");
      }
    }
  
    Newx(buffer, (sizeof(ffi_pl_function) + sizeof(ffi_pl_type*)*(items-4)), char);
    self = (ffi_pl_function*)buffer;
    Newx(signature, items-4, ffi_type*);
    
    self->address = address;
    self->return_type = return_type;
    
    for(i=0; i<(items-4); i++)
    {
      arg = ST(i+4);
      self->argument_types[i] = INT2PTR(ffi_pl_type*, SvIV((SV*) SvRV(arg)));
      signature[i] = self->argument_types[i]->ffi_type;
    }
    
    status = ffi_prep_cif(
      &self->ffi_cif,            /* ffi_cif */
      FFI_DEFAULT_ABI,           /* ffi_abi */
      items-4,                   /* argument count */
      return_type->ffi_type,     /* return type */
      signature
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
    int i;
    void **pointers;
    void *arguments;
    SV *arg;
    ffi_arg result;
  CODE:
    if(items-1 != self->ffi_cif.nargs)
      croak("wrong number of arguments");
  
    buffer_size = (FFI_SIZEOF_ARG + sizeof(void*)) * self->ffi_cif.nargs;
#ifdef HAVE_ALLOCA
    buffer = alloca(buffer_size);
#else
    Newx(buffer, buffer_size, char);
#endif
    pointers  = (void**) buffer;
    arguments =  (char*) &buffer[sizeof(void*)*self->ffi_cif.nargs];

    for(i=0; i<items-1; i++)
    {
      pointers[i] = (void*) &arguments[FFI_SIZEOF_ARG*i];
      
      if(self->argument_types[i]->platypus_type == FFI_PL_FFI)
      {
        arg = ST(i+1);
        switch(self->argument_types[i]->ffi_type->type)
        {
          case FFI_TYPE_VOID:
            /* do nothing?  probably not what you want */
            break;
          case FFI_TYPE_FLOAT:
            *((float*)pointers[i]) = SvNV(arg);
            break;
          case FFI_TYPE_DOUBLE:
            *((double*)pointers[i]) = SvNV(arg);
            break;
          case FFI_TYPE_LONGDOUBLE:
            /* FIXME */
            break;
          case FFI_TYPE_UINT8:
            *((uint8_t*)pointers[i]) = SvIV(arg);
            break;
          case FFI_TYPE_SINT8:
            *((int8_t*)pointers[i]) = SvIV(arg);
            break;
          case FFI_TYPE_UINT16:
            *((uint16_t*)pointers[i]) = SvIV(arg);
            break;
          case FFI_TYPE_SINT16:
            *((int16_t*)pointers[i]) = SvIV(arg);
            break;
          case FFI_TYPE_UINT32:
            *((uint32_t*)pointers[i]) = SvIV(arg);
            break;
          case FFI_TYPE_SINT32:
            *((int32_t*)pointers[i]) = SvIV(arg);
            break;
          case FFI_TYPE_UINT64:
            /* FIXME */
            break;
          case FFI_TYPE_SINT64:
            /* FIXME */
            break;
          case FFI_TYPE_POINTER:
            if(!SvOK(arg))
            {
              *((void**)pointers[i]) = NULL;
            }
            else
            {
              *((void**)pointers[i]) = INT2PTR(void*, SvIV(arg));
            }
            break;
        }
      }
      else if(self->argument_types[i]->platypus_type == FFI_PL_STRING)
      {
        *((char**)pointers[i]) = SvPV_nolen(ST(i+1));
      }
      else if(self->argument_types[i]->platypus_type == FFI_PL_CUSTOM)
      {
        croak("TODO");
      }
    }
    
    ffi_call(&self->ffi_cif, self->address, &result, pointers);    
#ifndef HAVE_ALLOCA
    Safefree(buffer);
#endif

    if(self->return_type->platypus_type == FFI_PL_FFI)
    {
      switch(self->return_type->ffi_type->type)
      {
        case FFI_TYPE_VOID:
          XSRETURN_EMPTY;
          break;
        case FFI_TYPE_FLOAT:
        case FFI_TYPE_DOUBLE:
        case FFI_TYPE_LONGDOUBLE:
        case FFI_TYPE_UINT8:
        case FFI_TYPE_SINT8:
        case FFI_TYPE_UINT16:
        case FFI_TYPE_SINT16:
        case FFI_TYPE_UINT32:
        case FFI_TYPE_SINT32:
        case FFI_TYPE_UINT64:
        case FFI_TYPE_SINT64:
        case FFI_TYPE_POINTER:
          break;
      }
    }
    else if(self->return_type->platypus_type == FFI_PL_STRING)
    {
    }
    else if(self->return_type->platypus_type == FFI_PL_CUSTOM)
    {
    }

void
DESTROY(self)
    ffi_pl_function *self
  CODE:
    SvREFCNT_dec(self->sv);
    Safefree(self->ffi_cif.arg_types);
    Safefree(self);

