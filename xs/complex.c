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

static void
set(SV *sv, SV *new_value, int imag)
{
  dSP;
  
  int count;
  double result = 0.0;

  ENTER;
  SAVETMPS;
  PUSHMARK(SP);
  XPUSHs(sv);
  XPUSHs(new_value);
  PUTBACK;
  
  count = call_pv(imag ? "Math::Complex::Im" : "Math::Complex::Re", G_DISCARD);
  
  FREETMPS;
  LEAVE;
}

void
ffi_pl_perl_to_complex_float(SV *sv, float *ptr)
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
  else if(SvOK(sv))
  {
    ptr[0] = SvNV(sv);
    ptr[1] = 0.0;
  }
  else
  {
    ptr[0] = 0.0;
    ptr[1] = 0.0;
  }
}

void
ffi_pl_complex_float_to_perl(SV *sv, float *ptr)
{
  if(SvOK(sv) && sv_isobject(sv) && sv_derived_from(sv, "Math::Complex"))
  {
    /* the complex variable is a Math::Complex object */
    set(sv, sv_2mortal(newSVnv(ptr[0])), 0);
    set(sv, sv_2mortal(newSVnv(ptr[1])), 1);    
  }
  else if(SvROK(sv) && SvTYPE(SvRV(sv)) == SVt_PVAV)
  {
    /* the compex variable is already an array */
    AV *av = (AV*) SvRV(sv);
    av_store(av, 0, newSVnv(ptr[0]));
    av_store(av, 1, newSVnv(ptr[1]));
  }
  else
  {
    /* the complex variable is something else and an array needs to be created */
    SV *values[2];
    AV *av;
    values[0] = newSVnv(ptr[0]);
    values[1] = newSVnv(ptr[1]);
    av = av_make(2, values);
    sv_setsv(sv, newRV_noinc((SV*)av));
  }
}

void
ffi_pl_perl_to_complex_double(SV *sv, double *ptr)
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
ffi_pl_complex_double_to_perl(SV *sv, double *ptr)
{
  if(SvOK(sv) && sv_isobject(sv) && sv_derived_from(sv, "Math::Complex"))
  {
    /* the complex variable is a Math::Complex object */
    set(sv, sv_2mortal(newSVnv(ptr[0])), 0);
    set(sv, sv_2mortal(newSVnv(ptr[1])), 1);    
  }
  else if(SvROK(sv) && SvTYPE(SvRV(sv)) == SVt_PVAV)
  {
    /* the compex variable is already an array */
    AV *av = (AV*) SvRV(sv);
    av_store(av, 0, newSVnv(ptr[0]));
    av_store(av, 1, newSVnv(ptr[1]));
  }
  else
  {
    /* the complex variable is something else and an array needs to be created */
    SV *values[2];
    AV *av;
    values[0] = newSVnv(ptr[0]);
    values[1] = newSVnv(ptr[1]);
    av = av_make(2, values);
    sv_setsv(sv, newRV_noinc((SV*)av));
  }
}

