#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include "ffi_platypus.h"
#include "ffi_platypus_guts.h"

SV*
ffi_pl_custom_perl(SV *subref, SV *in_arg, int i)
{
  if(subref == NULL)
  {
    return newSVsv(in_arg);
  }
  else
  {
    dSP;

    int count;
    SV *out_arg;

    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(in_arg);
    XPUSHs(sv_2mortal(newSViv(i)));
    PUTBACK;

    count = call_sv(subref, G_ARRAY);

    SPAGAIN;

    if(count >= 1)
      out_arg = SvREFCNT_inc(POPs);
    else
      out_arg = NULL;

    PUTBACK;
    FREETMPS;
    LEAVE;

    return out_arg;
  }
}

void
ffi_pl_custom_perl_cb(SV *subref, SV *in_arg, int i)
{
  dSP;
  ENTER;
  SAVETMPS;
  PUSHMARK(SP);
  XPUSHs(in_arg);
  XPUSHs(sv_2mortal(newSViv(i)));
  PUTBACK;
  call_sv(subref, G_VOID|G_DISCARD);
  FREETMPS;
  LEAVE;
}
