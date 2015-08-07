MODULE = FFI::Platypus PACKAGE = FFI::Platypus::Function

ffi_pl_function *
new(class, platypus, address, abi, return_type, ...)
    const char *class
    SV *platypus
    void *address
    int abi
    ffi_pl_type *return_type
  PREINIT:
    ffi_pl_function *self;
    int i,n,j;
    SV* arg;
    void *buffer;
    ffi_type *ffi_return_type;
    ffi_type **ffi_argument_types;
    ffi_status ffi_status;
    ffi_pl_type *tmp;
    ffi_abi ffi_abi;
    int extra_arguments;
  CODE:
  
    ffi_abi = abi == -1 ? FFI_DEFAULT_ABI : abi;
    
    for(i=0,extra_arguments=0; i<(items-5); i++)
    {
      arg = ST(i+5);
      if(!(sv_isobject(arg) && sv_derived_from(arg, "FFI::Platypus::Type")))
      {
        croak("non-type parameter passed in as type");
      }
      tmp = INT2PTR(ffi_pl_type*, SvIV((SV*) SvRV(arg)));
      if(tmp->platypus_type == FFI_PL_CUSTOM_PERL)
        extra_arguments += tmp->extra[0].custom_perl.argument_count;
    }
  
    Newx(buffer, (sizeof(ffi_pl_function) + sizeof(ffi_pl_type*)*(items-5+extra_arguments)), char);
    self = (ffi_pl_function*)buffer;
    Newx(ffi_argument_types, items-5+extra_arguments, ffi_type*);
    
    self->address = address;
    self->return_type = return_type;
    
    if(return_type->platypus_type == FFI_PL_NATIVE 
    || return_type->platypus_type == FFI_PL_CUSTOM_PERL
    || return_type->platypus_type == FFI_PL_EXOTIC_FLOAT)
    {
      ffi_return_type = return_type->ffi_type;
    }
    else
    {
      ffi_return_type = &ffi_type_pointer;
    }
    
    for(i=0,n=0; i<(items-5); i++,n++)
    {
      arg = ST(i+5);
      self->argument_types[n] = INT2PTR(ffi_pl_type*, SvIV((SV*) SvRV(arg)));
      if(self->argument_types[n]->platypus_type == FFI_PL_NATIVE
      || self->argument_types[n]->platypus_type == FFI_PL_CUSTOM_PERL
      || self->argument_types[n]->platypus_type == FFI_PL_EXOTIC_FLOAT)
      {
        ffi_argument_types[n] = self->argument_types[n]->ffi_type;
      }
      else
      {
        ffi_argument_types[n] = &ffi_type_pointer;
      }
      if(self->argument_types[n]->platypus_type == FFI_PL_CUSTOM_PERL
      && self->argument_types[n]->extra[0].custom_perl.argument_count > 0)
      {
        for(j=1; j-1 < self->argument_types[n]->extra[0].custom_perl.argument_count; j++)
        {
          self->argument_types[n+j] = self->argument_types[n];
          ffi_argument_types[n+j] = self->argument_types[n]->ffi_type;
        }

        n += self->argument_types[n]->extra[0].custom_perl.argument_count;
      }
    }
    
    ffi_status = ffi_prep_cif(
      &self->ffi_cif,            /* ffi_cif     | */
      ffi_abi,                   /* ffi_abi     | */
      items-5+extra_arguments,   /* int         | argument count */
      ffi_return_type,           /* ffi_type *  | return type */
      ffi_argument_types         /* ffi_type ** | argument types */
    );
    
    if(ffi_status != FFI_OK)
    {
      if(!PL_dirty)
      {
        Safefree(self);
        Safefree(ffi_argument_types);
      }
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
    int i, n, perl_arg_index;
    SV *arg;
    ffi_pl_result result;
    ffi_pl_arguments *arguments;
    void **argument_pointers;
    dMY_CXT;
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
      croak("self is not of type FFI::Platypus::Function");

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
      cv = get_cv(perl_name,0);
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
    if(!PL_dirty)
    {
      Safefree(self->ffi_cif.arg_types);
      Safefree(self);
    }

