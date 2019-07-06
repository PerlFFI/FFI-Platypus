MODULE = FFI::Platypus PACKAGE = FFI::Platypus::Function::Function

ffi_pl_function *
new(class, platypus, address, abi, var_fixed_args, return_type, ...)
    const char *class
    SV *platypus
    void *address
    int abi
    int var_fixed_args
    ffi_pl_type *return_type
  PREINIT:
    ffi_pl_function *self;
    int i,n,j;
    SV* arg;
    void *buffer;
    ffi_type *ffi_return_type;
    ffi_type **ffi_argument_types;
    ffi_status ffi_status;
    ffi_abi ffi_abi;
    int extra_arguments;
  CODE:
    (void)class;
#ifndef FFI_PL_PROBE_VARIADIC
    if(var_fixed_args != -1)
    {
      croak("variadic functions are not supported by some combination of your libffi/compiler/platypus");
    }
#endif
    ffi_abi = abi == -1 ? FFI_DEFAULT_ABI : abi;

    for(i=0,extra_arguments=0; i<(items-6); i++)
    {
      ffi_pl_type *arg_type;
      arg = ST(i+6);
      if(!(sv_isobject(arg) && sv_derived_from(arg, "FFI::Platypus::Type")))
      {
        croak("non-type parameter passed in as type");
      }
      arg_type = INT2PTR(ffi_pl_type*, SvIV((SV*) SvRV(arg)));
      if((arg_type->type_code & FFI_PL_SHAPE_MASK) == FFI_PL_SHAPE_CUSTOM_PERL)
        extra_arguments += arg_type->extra[0].custom_perl.argument_count;
    }

    Newx(buffer, (sizeof(ffi_pl_function) + sizeof(ffi_pl_type*)*(items-6+extra_arguments)), char);
    self = (ffi_pl_function*)buffer;
    Newx(ffi_argument_types, items-6+extra_arguments, ffi_type*);

    self->address = address;
    self->return_type = return_type;
    ffi_return_type = ffi_pl_type_to_libffi_type(return_type);

    for(i=0,n=0; i<(items-6); i++,n++)
    {
      arg = ST(i+6);
      self->argument_types[n] = INT2PTR(ffi_pl_type*, SvIV((SV*) SvRV(arg)));
      ffi_argument_types[n] = ffi_pl_type_to_libffi_type(self->argument_types[n]);

      if((self->argument_types[n]->type_code & FFI_PL_SHAPE_MASK) == FFI_PL_SHAPE_CUSTOM_PERL
      && self->argument_types[n]->extra[0].custom_perl.argument_count > 0)
      {
        for(j=1; j-1 < self->argument_types[n]->extra[0].custom_perl.argument_count; j++)
        {
          self->argument_types[n+j] = self->argument_types[n];
          ffi_argument_types[n+j] = ffi_pl_type_to_libffi_type(self->argument_types[n]);
        }

        n += self->argument_types[n]->extra[0].custom_perl.argument_count;
      }
    }

    if(var_fixed_args == -1)
    {
      ffi_status = ffi_prep_cif(
        &self->ffi_cif,            /* ffi_cif     | */
        ffi_abi,                   /* ffi_abi     | */
        items-6+extra_arguments,   /* int         | argument count */
        ffi_return_type,           /* ffi_type *  | return type */
        ffi_argument_types         /* ffi_type ** | argument types */
      );
    }
    else
    {
#ifdef FFI_PL_PROBE_VARIADIC
      ffi_status = ffi_prep_cif_var(
        &self->ffi_cif,                           /* ffi_cif     | */
        ffi_abi,                                  /* ffi_abi     | */
        var_fixed_args,                           /* int         | fixed argument count */
        items-6+extra_arguments-var_fixed_args,   /* int         | var argument count */
        ffi_return_type,                          /* ffi_type *  | return type */
        ffi_argument_types                        /* ffi_type ** | argument types */
      );
#endif
    }

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

    self->platypus_sv = SvREFCNT_inc_simple_NN(platypus);

    RETVAL = self;
  OUTPUT:
    RETVAL

void
call(self, ...)
    ffi_pl_function *self
  PREINIT:
    int i, n, perl_arg_index;
    SV *arg;
    ffi_pl_result result;
    ffi_pl_arguments *arguments;
    void **argument_pointers;
    dMY_CXT;
  CODE:
#define EXTRA_ARGS 1
    {
#include "ffi_platypus_call.h"
    }

void
_attach(self, perl_name, path_name, proto)
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
    SvREFCNT_inc_simple_void_NN(self);

SV*
_sub_ref(self, path_name)
    SV *self
    ffi_pl_string path_name
  PREINIT:
    CV* cv;
    SV *ref;
  CODE:
    cv =newXS(NULL, ffi_pl_sub_call, path_name);
    CvXSUBANY(cv).any_ptr = (void *) INT2PTR(ffi_pl_function*, SvIV((SV*) SvRV(self)));
    /*
     * No coresponding decrement !!
     * once attached, you can never free the function object, or the FFI::Platypus
     * it was created from.
     */
    SvREFCNT_inc_simple_void_NN(self);
    RETVAL = newRV_inc((SV*)cv);
  OUTPUT:
    RETVAL


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

MODULE = FFI::Platypus PACKAGE = FFI::Platypus::Function::Wrapper

void
_set_prototype(proto, code)
    SV *proto;
    SV *code;
  PROTOTYPE: $$
  PREINIT:
    SV *cv; /* not CV */
  CODE:
    SvGETMAGIC(code);
    cv = SvRV(code);
    sv_copypv(cv, proto);
