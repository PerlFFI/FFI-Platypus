#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"
#include "ffi_platypus.h"
#include "ffi_platypus_guts.h"
#include "perl_math_int64.h"

#define MY_CXT_KEY "FFI::Platypus::_guts" XS_VERSION

typedef struct {
  ffi_pl_arguments *current_argv;
  /*
   *  0 not loaded
   *  1 loaded ok
   *  2 attempted load, but errored
   */
  int loaded_math_longdouble;
  AV* custom_keepers;
} my_cxt_t;

START_MY_CXT

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
  HV *stash;
  MY_CXT_INIT;
  MY_CXT.current_argv           = NULL;
  MY_CXT.loaded_math_longdouble = 0;
  MY_CXT.custom_keepers         = get_av("FFI::Platypus::keep", GV_ADD);
  PERL_MATH_INT64_LOAD_OR_CROAK;

  stash = gv_stashpv("FFI::Platypus", TRUE);
  newCONSTSUB(stash, "_cast0", newSVuv(PTR2UV(cast0)));
  newCONSTSUB(stash, "_cast1", newSVuv(PTR2UV(cast1)));
}

void
CLONE(...)
  CODE:
    MY_CXT_CLONE;
    MY_CXT.custom_keepers         = get_av("FFI::Platypus::keep", GV_ADD);

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
INCLUDE: ../../xs/Buffer.xs

