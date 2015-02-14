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
  
  ENTER;
  SAVETMPS;
  
  PUSHMARK(SP);
  XPUSHs(sv_2mortal(newSVpv(pm_name,0)));
  PUTBACK;
  
  call_pv("FFI::Platypus::_have_pm", G_SCALAR);
  
  SPAGAIN;
  
  value = POPi;
  
  PUTBACK;
  FREETMPS;
  LEAVE;
  
  return value;
}


