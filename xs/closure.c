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

  /* TODO: eval ? */
  count = call_sv(closure->coderef, closure->flags);

  if(closure->flags & G_DISCARD)
    return;

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
      /* TODO */
      break;
  }

  FREETMPS;
  LEAVE;
}

