#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include "ffi_platypus.h"
#include "ffi_platypus_guts.h"

static double
decompose(SV *sv, int imag)
{
  /* Re(z) */
  dSP;
  
  int count;
  double result = 0.0;

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

void
ffi_pl_perl_complex_float(SV *sv, float *ptr)
{
  if(sv_isobject(sv) && sv_derived_from(sv, "Math::Complex"))
  {
    ptr[0] = decompose(sv, 0);
    ptr[1] = decompose(sv, 1);
  }
  else if(SvROK(sv) && SvTYPE(SvRV(sv)) == SVt_PVAV)
  {
    AV *av = (AV*) SvRV(sv);
    SV **real_sv, **imag_sv;
    real_sv = av_fetch(av, 0, 0);
    imag_sv = av_fetch(av, 1, 0);
    ptr[0] = real_sv != NULL ? SvNV(*real_sv) : 0.0;
    ptr[1]= imag_sv != NULL ? SvNV(*imag_sv) : 0.0;
  }
  else
  {
    ptr[0] = SvNV(sv);
    ptr[1] = 0.0;
  }
}

void
ffi_pl_perl_complex_double(SV *sv, double *ptr)
{
  if(sv_isobject(sv) && sv_derived_from(sv, "Math::Complex"))
  {
    ptr[0] = decompose(sv, 0);
    ptr[1] = decompose(sv, 1);
  }
  else if(SvROK(sv) && SvTYPE(SvRV(sv)) == SVt_PVAV)
  {
    AV *av = (AV*) SvRV(sv);
    SV **real_sv, **imag_sv;
    real_sv = av_fetch(av, 0, 0);
    imag_sv = av_fetch(av, 1, 0);
    ptr[0] = real_sv != NULL ? SvNV(*real_sv) : 0.0;
    ptr[1]= imag_sv != NULL ? SvNV(*imag_sv) : 0.0;
  }
  else
  {
    ptr[0] = SvNV(sv);
    ptr[1] = 0.0;
  }
}
