	#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include "ffi_platypus.h"

void
ffi_pl_closure_call(ffi_cif *ffi_cif, void *result, void **arguments, void *user)
{
  dSP;

  ffi_pl_closure *closure = (ffi_pl_closure*) user;
  ffi_pl_type_extra_closure *extra = &closure->type->extra[0].closure;
  int flags = extra->flags;
  int i;
  int count;
  SV *sv;

  if(!(flags & G_NOARGS))
  {
    ENTER;
    SAVETMPS;
  }

  PUSHMARK(SP);

  if(!(flags & G_NOARGS))
  {
    for(i=0; i< ffi_cif->nargs; i++)
    {
      if(extra->argument_types[i]->platypus_type == FFI_PL_FFI)
      {
        switch(extra->argument_types[i]->ffi_type->type)
        {
          case FFI_TYPE_VOID:
            break;
          case FFI_TYPE_UINT8:
            sv = sv_newmortal();
            sv_setuv(sv, *((uint8_t*)arguments[i]));
            XPUSHs(sv);
            break;
          case FFI_TYPE_SINT8:
            sv = sv_newmortal();
            sv_setiv(sv, *((int8_t*)arguments[i]));
            XPUSHs(sv);
            break;
        }
      }
    }
    PUTBACK;
  }

  /* TODO: what to do in the event of die */
  count = call_sv(closure->coderef, flags);

  if(!(flags & G_DISCARD))
  {
    SPAGAIN;

    if(count != 1)
      sv = &PL_sv_undef;
    else
      sv = POPs;

    if(extra->return_type->platypus_type == FFI_PL_FFI)
    {
      switch(extra->return_type->ffi_type->type)
      {
        case FFI_TYPE_UINT8:
          *((uint8_t*)result) = SvUV(sv);
          break;
        case FFI_TYPE_SINT8:
          *((int8_t*)result) = SvIV(sv);
          break;
      }
    }

    PUTBACK;
  }

  if(!(flags & G_NOARGS))
  {
    FREETMPS;
    LEAVE;
  }
}

