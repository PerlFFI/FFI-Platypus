#ifndef FFI_PLATYPUS_GUTS_H
#define FFI_PLATYPUS_GUTS_H
#ifdef __cplusplus
extern "C" {
#endif

void ffi_pl_closure_call(ffi_cif *, void *, void **, void *);
void ffi_pl_closure_add_data(SV *closure, ffi_pl_closure *closure_data);
ffi_pl_closure *ffi_pl_closure_get_data(SV *closure, ffi_pl_type *type);
SV*  ffi_pl_custom_perl(SV*,SV*,int);
void ffi_pl_custom_perl_cb(SV *, SV*, int);
HV *ffi_pl_get_type_meta(ffi_pl_type *);
size_t ffi_pl_sizeof(ffi_pl_type *);
void ffi_pl_perl_complex_float(SV *sv, float *ptr);
void ffi_pl_perl_complex_double(SV *sv, double *ptr);

#define ffi_pl_perl_to_long_double(sv, ptr)                           \
  if(!SvOK(sv))                                                       \
  {                                                                   \
    *(ptr) = 0.0L;                                                    \
  }                                                                   \
  else if(sv_isobject(sv) && sv_derived_from(sv, "Math::LongDouble")) \
  {                                                                   \
    *(ptr) = *INT2PTR(long double *, SvIV((SV*) SvRV(sv)));           \
  }                                                                   \
  else                                                                \
  {                                                                   \
    *(ptr) = (long double) SvNV(sv);                                  \
  }

/*
 * CAVEATS:
 *  - We are mucking about with the innerds of Math::LongDouble
 *    so if the innerds change we may break Math::LongDouble,
 *    FFI::Platypus or both!
 *  - This makes Math::LongDouble mutable.  Note however, that
 *    Math::LongDouble overloads ++ and increments the actual
 *    longdouble pointed to in memory, so we are at least not
 *    introducing the sin of mutability.  See LongDouble.xs
 *    C function _overload_inc.
 */

#define ffi_pl_long_double_to_perl(sv, ptr)                      \
  if(sv_isobject(sv) && sv_derived_from(sv, "Math::LongDouble")) \
  {                                                              \
    *INT2PTR(long double *, SvIV((SV*) SvRV(sv))) = *(ptr);      \
  }                                                              \
  else if(MY_CXT.have_math_longdouble)                           \
  {                                                              \
    long double *tmp;                                            \
    Newx(tmp, 1, long double);                                   \
    *tmp = *(ptr);                                               \
    sv_setref_pv(sv, "Math::LongDouble", (void*)tmp);            \
  }                                                              \
  else                                                           \
  {                                                              \
    sv_setnv(sv, *(ptr));                                        \
  }

#ifdef __cplusplus
}
#endif
#endif
