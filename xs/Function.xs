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
    
    if(return_type->platypus_type == FFI_PL_NATIVE || return_type->platypus_type == FFI_PL_CUSTOM_PERL)
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
      if(self->argument_types[i]->platypus_type == FFI_PL_NATIVE || self->argument_types[i]->platypus_type == FFI_PL_CUSTOM_PERL)
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
    ffi_pl_argument result;
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
    {
      /*
       * this ifdef is needed for Perl 5.8.8 support.
       * once we don't need to support 5.8.8 we can
       * remove this workaround (the ndef'd branch)
       */
#ifdef newXS_flags
      cv = newXSproto(perl_name, ffi_pl_sub_call, path_name, proto);
#else
      newXSproto(perl_name, ffi_pl_sub_call, path_name, proto);
      cv = (CV*)PL_Sv;
#endif
    }
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

