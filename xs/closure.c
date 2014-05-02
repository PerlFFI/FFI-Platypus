#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#define MATH_INT64_NATIVE_IF_AVAILABLE
#include "perl_math_int64.h"

#include <ffi.h>
#include <ffi_pl.h>
#include <ffi_pl_class.h>

void
ffi_pl_closure_call(ffi_cif *cif, void *result, void **arguments, void *user)
{
  dSP;
  int count;
  SV *sv_result;

  ffi_pl_closure *closure = (ffi_pl_closure*) user;

  if(!(closure->flags & G_NOARGS))
  {
    ENTER;
    SAVETMPS;
  }

  PUSHMARK(SP);

  if(!(closure->flags & G_NOARGS))
  {
    /* TODO: push args */
    PUTBACK;
  }

  /* TODO: what to do in the event of die ? */
  count = call_sv(closure->coderef, closure->flags);

  if(!(closure->flags & G_DISCARD))
  {
    SPAGAIN;

    if(count != 1)
      sv_result = &PL_sv_undef;
    else
      sv_result= POPs;

    switch(closure->signature->return_type->reftype)
    {
      case FFI_PL_REF_NONE:
        ffi_pl_sv2ffi(result, sv_result, closure->signature->return_type);
        break;
      case FFI_PL_REF_POINTER:
        if(!SvOK(sv_result))
        {
          *((void**)result) = NULL;
        }
        else if(SvROK(sv_result))
        {
          if(sv_isobject(sv_result) && sv_derived_from(sv_result, "FFI::Platypus::Closure"))
          {
            /* TODO: warning/fail if this isn't a void * */
            ffi_pl_closure *closure = INT2PTR(ffi_pl_closure *, SvIV((SV *) SvRV(sv_result)));
            *((void**)result) = closure->function_pointer;
          }
          else if(closure->signature->return_type->ffi_type->type == FFI_TYPE_VOID)
          {
            /* TODO: fail if type is void * */
          }
          else
          {
            Renew(closure->most_recent_return_value, FFI_SIZEOF_ARG, char);
            *((void**)result) = &closure->most_recent_return_value;
            ffi_pl_sv2ffi(*((void**)result), SvRV(sv_result), closure->signature->return_type);
          }
        }
        else
        {
          *((void**)result) = INT2PTR(void *, SvIV(sv_result));
        }
        break;
    }

    PUTBACK;
  }

  if(!(closure->flags & G_NOARGS))
  {
    FREETMPS;
    LEAVE;
  }
}

