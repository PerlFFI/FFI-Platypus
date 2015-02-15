#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include "ffi_platypus.h"

int
have_pm(const char *pm_name)
{
  dSP;
  int value;
  int count;

  ENTER;
  SAVETMPS;
  PUSHMARK(SP);
  XPUSHs(sv_2mortal(newSVpv(pm_name,0)));
  PUTBACK;

  count = call_pv("FFI::Platypus::_have_pm", G_SCALAR | G_EVAL);

  SPAGAIN;

  value = count >= 1 ? POPi : 0;

  PUTBACK;
  FREETMPS;
  LEAVE;

  return value;
}


