#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include "ffi_platypus.h"
#include "ffi_platypus_guts.h"

double
ffi_pl_perl_complex(SV *sv, int imag)
{
  /* Re(z) */
  dSP;
  
  int count;
  double complex result = 0.0;

  ENTER;
  SAVETMPS;
  PUSHMARK(SP);
  XPUSHs(sv);
  PUTBACK;
  
  count = call_pv(imag ? "Math::Complex::Im" : "Math::Complex::Re", G_ARRAY);
  
  SPAGAIN;
  
  if(count >= 1)
    result = POPn;
  
  PUTBACK;
  FREETMPS;
  LEAVE;
  
  return result;
}

