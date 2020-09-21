#include "ffi_platypus_config.h"
#ifndef HAVE_IV_IS_64
/* imported from Math::Int64 0.34 6 December 2014 by PLICEASE */
/*
 * perl_math_int64.c - This file is in the public domain
 * Author: Salvador Fandino <sfandino@yahoo.com>
 *
 * Generated on: 2014-10-30 11:43:56
 * Math::Int64 version: 0.33
 * Module::CAPIMaker version: 0.02
 */

#include "EXTERN.h"
#include "perl.h"
#include "ppport.h"

#ifdef __MINGW32__
#include <stdint.h>
#endif

#ifdef _MSC_VER
#include <stdlib.h>
typedef __int64 int64_t;
typedef unsigned __int64 uint64_t;
#endif

/* you may need to add a typemap for int64_t here if it is not defined
   by default in your C header files */

HV *math_int64_c_api_hash;
int math_int64_c_api_min_version;
int math_int64_c_api_max_version;

int64_t   (*math_int64_c_api_SvI64)(pTHX_ SV*);
int       (*math_int64_c_api_SvI64OK)(pTHX_ SV*);
uint64_t  (*math_int64_c_api_SvU64)(pTHX_ SV*);
int       (*math_int64_c_api_SvU64OK)(pTHX_ SV*);
SV *      (*math_int64_c_api_newSVi64)(pTHX_ int64_t);
SV *      (*math_int64_c_api_newSVu64)(pTHX_ uint64_t);
uint64_t  (*math_int64_c_api_randU64)(pTHX);

int
perl_math_int64_load(int required_version) {
    dTHX;
    SV **svp;
    eval_pv("require Math::Int64", TRUE);
    if (SvTRUE(ERRSV)) return 0;

   math_int64_c_api_hash = get_hv("Math::Int64::C_API", 0);
    if (!math_int64_c_api_hash) {
        sv_setpv(ERRSV, "Unable to load Math::Int64 C API");
        SvSETMAGIC(ERRSV);
        return 0;
    }

    svp = hv_fetch(math_int64_c_api_hash, "min_version", 11, 0);
    if (!svp) svp = hv_fetch(math_int64_c_api_hash, "version", 7, 1);
    if (!svp || !*svp) {
        sv_setpv(ERRSV, "Unable to retrieve C API version for Math::Int64");
        SvSETMAGIC(ERRSV);
        return 0;
    }
    math_int64_c_api_min_version = SvIV(*svp);

    svp = hv_fetch(math_int64_c_api_hash, "max_version", 11, 0);
    if (!svp) svp = hv_fetch(math_int64_c_api_hash, "version", 7, 1);
    if (!svp || !*svp) {
        sv_setpv(ERRSV, "Unable to retrieve C API version for Math::Int64");
        SvSETMAGIC(ERRSV);
        return 0;
    }
    math_int64_c_api_max_version = SvIV(*svp);

    if ((required_version < math_int64_c_api_min_version) ||
        (required_version > math_int64_c_api_max_version)) {
        sv_setpvf(ERRSV,
                  "Math::Int64 C API version mismatch. "
                  "The installed module supports versions %d to %d but %d is required",
                  math_int64_c_api_min_version,
                  math_int64_c_api_max_version,
                  required_version);
        SvSETMAGIC(ERRSV);
        return 0;
    }

    svp = hv_fetch(math_int64_c_api_hash, "SvI64", 5, 0);
    if (!svp || !*svp) {
        sv_setpv(ERRSV, "Unable to fetch pointer 'SvI64' C function from Math::Int64");
        SvSETMAGIC(ERRSV);
        return 0;
    }
    math_int64_c_api_SvI64 = INT2PTR(void *, SvIV(*svp));
    svp = hv_fetch(math_int64_c_api_hash, "SvI64OK", 7, 0);
    if (!svp || !*svp) {
        sv_setpv(ERRSV, "Unable to fetch pointer 'SvI64OK' C function from Math::Int64");
        SvSETMAGIC(ERRSV);
        return 0;
    }
    math_int64_c_api_SvI64OK = INT2PTR(void *, SvIV(*svp));
    svp = hv_fetch(math_int64_c_api_hash, "SvU64", 5, 0);
    if (!svp || !*svp) {
        sv_setpv(ERRSV, "Unable to fetch pointer 'SvU64' C function from Math::Int64");
        SvSETMAGIC(ERRSV);
        return 0;
    }
    math_int64_c_api_SvU64 = INT2PTR(void *, SvIV(*svp));
    svp = hv_fetch(math_int64_c_api_hash, "SvU64OK", 7, 0);
    if (!svp || !*svp) {
        sv_setpv(ERRSV, "Unable to fetch pointer 'SvU64OK' C function from Math::Int64");
        SvSETMAGIC(ERRSV);
        return 0;
    }
    math_int64_c_api_SvU64OK = INT2PTR(void *, SvIV(*svp));
    svp = hv_fetch(math_int64_c_api_hash, "newSVi64", 8, 0);
    if (!svp || !*svp) {
        sv_setpv(ERRSV, "Unable to fetch pointer 'newSVi64' C function from Math::Int64");
        SvSETMAGIC(ERRSV);
        return 0;
    }
    math_int64_c_api_newSVi64 = INT2PTR(void *, SvIV(*svp));
    svp = hv_fetch(math_int64_c_api_hash, "newSVu64", 8, 0);
    if (!svp || !*svp) {
        sv_setpv(ERRSV, "Unable to fetch pointer 'newSVu64' C function from Math::Int64");
        SvSETMAGIC(ERRSV);
        return 0;
    }
    math_int64_c_api_newSVu64 = INT2PTR(void *, SvIV(*svp));
    svp = hv_fetch(math_int64_c_api_hash, "randU64", 7, 0);
    if (!svp || !*svp) {
        sv_setpv(ERRSV, "Unable to fetch pointer 'randU64' C function from Math::Int64");
        SvSETMAGIC(ERRSV);
        return 0;
    }
    math_int64_c_api_randU64 = INT2PTR(void *, SvIV(*svp));

    return 1;
}
#endif
