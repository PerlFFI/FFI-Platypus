#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include "ffi_platypus.h"

#ifndef HAVE_IV_IS_64
#include "perl_math_int64.h"
#endif

void *cast0(void)
{
  return NULL;
}

void *cast1(void *value)
{
  return value;
}

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
    char *buffer;
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
      Newx(buffer, sizeof(ffi_pl_type) + sizeof(ffi_pl_type_extra_array), char);
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
      self->ffi_type = ffi_pl_name_to_type(type);
      if(self->ffi_type == NULL)
      {
        Safefree(self);
        self = NULL;
        croak("unknown ffi/platypus type: %s/%s", type, platypus_type);
      }
    }

    RETVAL = self;
  OUTPUT:
    RETVAL

ffi_pl_type *
_new_custom_perl(class, type, perl_to_ffi, ffi_to_perl, userdata)
    const char *class
    const char *type
    SV *perl_to_ffi
    SV *ffi_to_perl
    SV *userdata
  PREINIT:
    char *buffer;
    ffi_pl_type *self;
    ffi_type *ffi_type;
    ffi_pl_type_extra_custom_perl *custom;
  CODE:
    ffi_type = ffi_pl_name_to_type(type);
    if(ffi_type == NULL)
      croak("unknown ffi/platypus type: %s/custom", type);
      
    Newx(buffer, sizeof(ffi_pl_type) + sizeof(ffi_pl_type_extra_custom_perl), char);
    self = (ffi_pl_type*) buffer;
    self->platypus_type = FFI_PL_CUSTOM_PERL;
    self->ffi_type = ffi_type;
    
    custom = &self->extra[0].custom_perl;
    custom->perl_to_ffi = SvOK(perl_to_ffi) ? SvREFCNT_inc(perl_to_ffi) : NULL;
    custom->ffi_to_perl = SvOK(ffi_to_perl) ? SvREFCNT_inc(ffi_to_perl) : NULL;
    
    RETVAL = self;
  OUTPUT:
    RETVAL


ffi_pl_type *
_new_closure(class, return_type, ...)
    const char *class;
    ffi_pl_type *return_type
  PREINIT:
    char *buffer;
    ffi_pl_type *self, *tmp;
    int i;
    SV *arg;
    ffi_type *ffi_return_type;
    ffi_type **ffi_argument_types;
    ffi_status ffi_status;
  CODE:
    if(return_type->platypus_type == FFI_PL_CLOSURE)
    {
      /* TODO: this really should work, but the syntax need to be worked out */
      croak("returning a closure from a closure not supported");
    }
    
    for(i=0; i<(items-2); i++)
    {
      arg = ST(2+i);
      tmp = INT2PTR(ffi_pl_type*, SvIV((SV*)SvRV(arg)));
      if(tmp->platypus_type == FFI_PL_CLOSURE)
      {
        croak("passing closure into a closure not supported");
      }
    }
    
    Newx(buffer, sizeof(ffi_pl_type) + sizeof(ffi_pl_type_extra_closure) + sizeof(ffi_pl_type)*(items-2), char);
    Newx(ffi_argument_types, items-2, ffi_type*);
    self = (ffi_pl_type*) buffer;
    
    self->ffi_type = &ffi_type_pointer;
    self->platypus_type = FFI_PL_CLOSURE;
    self->extra[0].closure.return_type = return_type;
    self->extra[0].closure.flags = 0;
    
    if(return_type->platypus_type == FFI_PL_FFI)
    {
      ffi_return_type = return_type->ffi_type;
    }
    else
    {
      ffi_return_type = &ffi_type_pointer;
    }
    
    for(i=0; i<(items-2); i++)
    {
      arg = ST(2+i);
      self->extra[0].closure.argument_types[i] = INT2PTR(ffi_pl_type*, SvIV((SV*)SvRV(arg)));
      if(self->extra[0].closure.argument_types[i]->platypus_type == FFI_PL_FFI)
      {
        ffi_argument_types[i] = self->extra[0].closure.argument_types[i]->ffi_type;
      }
      else
      {
        ffi_argument_types[i] = &ffi_type_pointer;
      }
    }
    
    ffi_status = ffi_prep_cif(
      &self->extra[0].closure.ffi_cif,
      FFI_DEFAULT_ABI,
      items-2,
      ffi_return_type,
      ffi_argument_types
    );
    
    if(ffi_status != FFI_OK)
    {
      Safefree(self);
      Safefree(ffi_argument_types);
      if(ffi_status == FFI_BAD_TYPEDEF)
        croak("bad typedef");
      else if(ffi_status == FFI_BAD_ABI)
        croak("bad abi");
      else
        croak("unknown error with ffi_prep_cif");
    }

    if( items-2 == 0 )
    {
      self->extra[0].closure.flags |= G_NOARGS;
    }
    
    if(self->extra[0].closure.return_type->ffi_type->type == FFI_TYPE_VOID
    && self->extra[0].closure.return_type->platypus_type == FFI_PL_FFI)
    {
      self->extra[0].closure.flags |= G_DISCARD | G_VOID;
    }
    else
    {
      self->extra[0].closure.flags |= G_SCALAR;
    }
    
    RETVAL = self;
    
  OUTPUT:
    RETVAL

SV*
meta(self)
    ffi_pl_type *self
  PREINIT:
    HV *meta;
    extern void *ffi_pl_get_type_meta(ffi_pl_type*);
  CODE:
    meta = (HV*) ffi_pl_get_type_meta(self);
    RETVAL = newRV_noinc((SV*)meta);
  OUTPUT:
    RETVAL

void
DESTROY(self)
    ffi_pl_type *self
  PREINIT:
  CODE:
    if(self->platypus_type == FFI_PL_CLOSURE)
    {
      Safefree(self->extra[0].closure.ffi_cif.arg_types);
    }
    if(self->platypus_type == FFI_PL_CUSTOM_PERL)
    {
      ffi_pl_type_extra_custom_perl *custom;
      
      custom = &self->extra[0].custom_perl;
      
      if(custom->perl_to_ffi != NULL)
        SvREFCNT_dec(custom->perl_to_ffi);
      if(custom->ffi_to_perl != NULL)
        SvREFCNT_dec(custom->ffi_to_perl);
    }
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
    int i;
    SV* arg;
    void *buffer;
    ffi_type *ffi_return_type;
    ffi_type **ffi_argument_types;
    ffi_status ffi_status;
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
    Newx(ffi_argument_types, items-4, ffi_type*);
    
    self->address = address;
    self->return_type = return_type;
    
    if(return_type->platypus_type == FFI_PL_FFI || return_type->platypus_type == FFI_PL_CUSTOM_PERL)
    {
      ffi_return_type = return_type->ffi_type;
    }
    else
    {
      ffi_return_type = &ffi_type_pointer;
    }
    
    for(i=0; i<(items-4); i++)
    {
      arg = ST(i+4);
      self->argument_types[i] = INT2PTR(ffi_pl_type*, SvIV((SV*) SvRV(arg)));
      if(self->argument_types[i]->platypus_type == FFI_PL_FFI || self->argument_types[i]->platypus_type == FFI_PL_CUSTOM_PERL)
      {
        ffi_argument_types[i] = self->argument_types[i]->ffi_type;
      }
      else
      {
        ffi_argument_types[i] = &ffi_type_pointer;
      }
    }
    
    ffi_status = ffi_prep_cif(
      &self->ffi_cif,            /* ffi_cif     | */
      FFI_DEFAULT_ABI,           /* ffi_abi     | */
      items-4,                   /* int         | argument count */
      ffi_return_type,           /* ffi_type *  | return type */
      ffi_argument_types         /* ffi_type ** | argument types */
    );
    
    if(ffi_status != FFI_OK)
    {
      Safefree(self);
      Safefree(ffi_argument_types);
      if(ffi_status == FFI_BAD_TYPEDEF)
        croak("bad typedef");
      else if(ffi_status == FFI_BAD_ABI)
        croak("bad abi");
      else
        croak("unknown error with ffi_prep_cif");
    }
    
    self->platypus_sv = SvREFCNT_inc(platypus);

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
attach(self, perl_name, path_name, proto)
    SV *self
    const char *perl_name
    ffi_pl_string path_name
    ffi_pl_string proto
  PREINIT:
    CV* cv;
  CODE:
    if(!(sv_isobject(self) && sv_derived_from(self, "FFI::Platypus::Function")))
      croak(aTHX_ "self is not of type FFI::Platypus::Function");

    if(path_name == NULL)
      path_name = "unknown";

    if(proto == NULL)
      cv = newXS(perl_name, ffi_pl_sub_call, path_name);
    else
      cv = newXSproto(perl_name, ffi_pl_sub_call, path_name, proto);
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
    SvREFCNT_dec(self->platypus_sv);
    Safefree(self->ffi_cif.arg_types);
    Safefree(self);

