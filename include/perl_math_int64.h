/*
 * perl_math_int64.h - This file is in the public domain
 * Author: Salvador Fandino <sfandino@yahoo.com>
 * Version: 2.1
 *
 * Generated on: 2014-10-30 11:43:56
 * Math::Int64 version: 0.33
 * Module::CAPIMaker version: 0.02
 */

#if !defined (PERL_MATH_INT64_H_INCLUDED)
#define PERL_MATH_INT64_H_INCLUDED

#define MATH_INT64_C_API_REQUIRED_VERSION 2
#define MATH_INT64_VERSION MATH_INT64_C_API_REQUIRED_VERSION

int perl_math_int64_load(int required_version);

#define PERL_MATH_INT64_LOAD perl_math_int64_load(MATH_INT64_C_API_REQUIRED_VERSION)
#define PERL_MATH_INT64_LOAD_OR_CROAK \
    if (PERL_MATH_INT64_LOAD);        \
    else croak(NULL);
#define MATH_INT64_BOOT PERL_MATH_INT64_LOAD_OR_CROAK

extern HV *math_int64_c_api_hash;
extern int math_int64_c_api_min_version;
extern int math_int64_c_api_max_version;
#define math_int64_capi_version math_int64_c_api_max_version

#if (defined(MATH_INT64_NATIVE_IF_AVAILABLE) && (IVSIZE == 8))
#define MATH_INT64_NATIVE 1
#endif

extern int64_t   (*math_int64_c_api_SvI64)(pTHX_ SV*);
#define SvI64(a) ((*math_int64_c_api_SvI64)(aTHX_ (a)))
extern int       (*math_int64_c_api_SvI64OK)(pTHX_ SV*);
#define SvI64OK(a) ((*math_int64_c_api_SvI64OK)(aTHX_ (a)))
extern uint64_t  (*math_int64_c_api_SvU64)(pTHX_ SV*);
#define SvU64(a) ((*math_int64_c_api_SvU64)(aTHX_ (a)))
extern int       (*math_int64_c_api_SvU64OK)(pTHX_ SV*);
#define SvU64OK(a) ((*math_int64_c_api_SvU64OK)(aTHX_ (a)))
extern SV *      (*math_int64_c_api_newSVi64)(pTHX_ int64_t);
#define newSVi64(a) ((*math_int64_c_api_newSVi64)(aTHX_ (a)))
extern SV *      (*math_int64_c_api_newSVu64)(pTHX_ uint64_t);
#define newSVu64(a) ((*math_int64_c_api_newSVu64)(aTHX_ (a)))
extern uint64_t  (*math_int64_c_api_randU64)(pTHX);
#define randU64() ((*math_int64_c_api_randU64)(aTHX))


#if MATH_INT64_NATIVE

#undef newSVi64
#define newSVi64 newSViv
#undef newSVu64
#define newSVu64 newSVuv

#define sv_seti64 sv_setiv_mg
#define sv_setu64 sv_setuv_mg

#else

#define sv_seti64(target, i64) (sv_setsv_mg(target, sv_2mortal(newSVi64(i64))))
#define sv_setu64(target, u64) (sv_setsv_mg(target, sv_2mortal(newSVu64(u64))))

#endif

#endif