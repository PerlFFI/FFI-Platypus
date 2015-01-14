#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include "ffi_platypus.h"

SV*
ffi_pl_custom_perl(SV *subref, SV *in_arg)
{
  dSP;

  int count;
  SV *out_arg;

  ENTER;
  SAVETMPS;
  PUSHMARK(SP);
  XPUSHs(in_arg);
  PUTBACK;

  count = call_sv(subref, G_SCALAR);

  SPAGAIN;

  if(count == 0)
    out_arg = NULL;
  else
    out_arg = SvREFCNT_inc(POPs);

  PUTBACK;
  FREETMPS;
  LEAVE;

  return out_arg;
}
