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
   *  0 not loaded
   *  1 loaded ok
   *  2 attempted load, but errored
   */
  int loaded_math_longdouble;
} my_cxt_t;

START_MY_CXT

#if SIZEOF_VOIDP == 4
uint64_t
cast0(void)
{
  return 0LL;
}
#else
void *
cast0(void)
{
  return NULL;
}
#endif

#if SIZEOF_VOIDP == 4
uint64_t
cast1(uint64_t value)
{
  return value;
}
#else
void *
cast1(void *value)
{
  return value;
}
#endif

XS(ffi_pl_sub_call)
{
  ffi_pl_function *self;
  int i,n, perl_arg_index;
  SV *arg;
  ffi_pl_arguments *arguments;
  void **argument_pointers;

  dMY_CXT;
  dVAR; dXSARGS;

  self = (ffi_pl_function*) CvXSUBANY(cv).any_ptr;

  {
#define EXTRA_ARGS 0
#define FFI_PL_CALL_NO_RECORD_VALUE 1
#include "ffi_platypus_call.h"
  }
}

XS(ffi_pl_sub_call_rv)
{
  ffi_pl_function *self;
  int i,n, perl_arg_index;
  SV *arg;
  ffi_pl_arguments *arguments;
  void **argument_pointers;

  dMY_CXT;
  dVAR; dXSARGS;

  self = (ffi_pl_function*) CvXSUBANY(cv).any_ptr;

  {
#define EXTRA_ARGS 0
#define FFI_PL_CALL_RET_NO_NORMAL 1
#include "ffi_platypus_call.h"
  }
}

MODULE = FFI::Platypus PACKAGE = FFI::Platypus

BOOT:
{
  MY_CXT_INIT;
  MY_CXT.current_argv           = NULL;
  MY_CXT.loaded_math_longdouble = 0;
#ifndef HAVE_IV_IS_64
  PERL_MATH_INT64_LOAD_OR_CROAK;
#endif
}

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
