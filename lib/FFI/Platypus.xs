#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include "ffi_platypus.h"
#include "ffi_platypus_guts.h"

#ifndef HAVE_IV_IS_64
#include "perl_math_int64.h"
#endif

#define MY_CXT_KEY "FFI::Platypus::_guts" XS_VERSION

typedef struct {
  ffi_pl_arguments *current_argv;
  /*
   * -1 until we have checked
   *  0 tried, not there
   *  1 tried, is there
   */
  int have_math_longdouble;  /* Math::LongDouble */
  int have_math_complex;  /* Math::Complex    */

} my_cxt_t;

START_MY_CXT

void *cast0(void)
{
  return NULL;
}

void *cast1(void *value)
{
  return value;
}

XS(ffi_pl_sub_call)
{
  ffi_pl_function *self;
  int i,n, perl_arg_index;
  SV *arg;
  ffi_pl_result result;
  ffi_pl_arguments *arguments;
  void **argument_pointers;
  
  dMY_CXT;
  dVAR; dXSARGS;
  
  self = (ffi_pl_function*) CvXSUBANY(cv).any_ptr;

#define EXTRA_ARGS 0
  {
#include "ffi_platypus_call.h"
  }
}

#define probe_for_math_stuff(type_code)                                    \
    if((type_code & FFI_PL_BASE_MASK) == FFI_PL_BASE_FLOAT &&              \
       (type_code & FFI_PL_SIZE_MASK) == FFI_PL_SIZE_128)                  \
    {                                                                      \
      if(MY_CXT.have_math_longdouble == -1)                                \
        MY_CXT.have_math_longdouble = have_pm("Math::LongDouble");         \
    }                                                                      \
    else if((type_code & FFI_PL_BASE_MASK) == FFI_PL_BASE_COMPLEX)         \
    {                                                                      \
      if(MY_CXT.have_math_complex == -1)                                   \
        MY_CXT.have_math_complex = have_pm("Math::Complex");               \
    }

MODULE = FFI::Platypus PACKAGE = FFI::Platypus

BOOT:
{
  MY_CXT_INIT;
  MY_CXT.current_argv         = NULL;
  MY_CXT.have_math_longdouble = -1;
  MY_CXT.have_math_complex    = -1;
#ifndef HAVE_IV_IS_64
  PERL_MATH_INT64_LOAD_OR_CROAK;
#endif
}

int
_have_math_longdouble(value = -2)
    int value
  PREINIT:
    dMY_CXT;
  CODE:
    if(value != -2)
      MY_CXT.have_math_longdouble = value;
    RETVAL = MY_CXT.have_math_longdouble;
  OUTPUT:
    RETVAL

int
_have_math_complex(value = -2)
    int value
  PREINIT:
    dMY_CXT;
  CODE:
    if(value != -2)
      MY_CXT.have_math_complex = value;
    RETVAL = MY_CXT.have_math_complex;
  OUTPUT:
    RETVAL

int
_have_type(name)
    const char *name
  CODE:
    RETVAL = !strcmp(name, "string") || ffi_pl_name_to_code(name) != -1;
  OUTPUT:
    RETVAL

void
CLONE(...)
  CODE:
    MY_CXT_CLONE;

INCLUDE: ../../xs/DL.xs
INCLUDE: ../../xs/Internal.xs
INCLUDE: ../../xs/Type.xs
INCLUDE: ../../xs/TypeParser.xs
INCLUDE: ../../xs/Function.xs
INCLUDE: ../../xs/ClosureData.xs
INCLUDE: ../../xs/API.xs
INCLUDE: ../../xs/ABI.xs
INCLUDE: ../../xs/Record.xs
INCLUDE: ../../xs/Closure.xs
