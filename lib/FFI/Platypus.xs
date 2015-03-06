#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include "ffi_platypus.h"
#include "ffi_platypus_guts.h"

#ifndef HAVE_IV_IS_64
#include "perl_math_int64.h"
#endif

ffi_pl_arguments *current_argv = NULL;

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
  char *buffer;
  size_t buffer_size;
  int i,n, perl_arg_index;
  SV *arg;
  ffi_pl_result result;
  ffi_pl_arguments *arguments;
  void **argument_pointers;
  
  dVAR; dXSARGS;
  
  self = (ffi_pl_function*) CvXSUBANY(cv).any_ptr;

#define EXTRA_ARGS 0
#include "ffi_platypus_call.h"
}

static ffi_pl_function *
ffi_pl_make_method(ffi_pl_cached_method *cached, SV *object)
{
  dVAR;
  dSP;
  int count;

  ffi_pl_function *function;
  SV *function_object;

  ENTER;
  SAVETMPS;
  PUSHMARK(SP);
  XPUSHs(object);
  XPUSHs(newRV_noinc((SV*)cached->other_methods));
  PUTBACK;

  count = call_pv("FFI::Platypus::_make_attach_method", G_SCALAR);
  SPAGAIN;

  if(count != 1)
  {
    croak("make_attach_method failed");
  }

  function_object = POPs;

  if(!function_object || !SvROK(function_object)
  || !sv_derived_from(function_object, "FFI::Platypus::Function"))
  {
    croak("make_attach_method failed");
  }

  function = INT2PTR(ffi_pl_function *, SvIV(SvRV(function_object)));

  if(SvROK(object))
  {
    cached->weakref = newRV_inc(SvRV(object));
    sv_rvweaken(cached->weakref);
    cached->function = function;
  }

  FREETMPS;
  LEAVE;

  return function;
}

XS(ffi_pl_method_call)
{
  ffi_pl_cached_method *cached;
  ffi_pl_function *self;
  char *buffer;
  size_t buffer_size;
  int i,n, perl_arg_index;
  SV *arg;
  ffi_pl_result result;
  ffi_pl_arguments *arguments;
  void **argument_pointers;

  dVAR; dXSARGS;

  cached = (ffi_pl_cached_method *) CvXSUBANY(cv).any_ptr;
  self = cached->function;

  if(!cached->weakref || !SvROK(cached->weakref)
  || (SvRV(cached->weakref) != SvRV(ST(0))))
  {
    self = ffi_pl_make_method(cached, ST(0));

    if(!self) {
      croak("could not generate a method on demand");
    }
  }

#define EXTRA_ARGS 1
#include "ffi_platypus_call.h"
}

/*
 * -1 until we have checked
 *  0 tried, not there
 *  1 tried, is there
 */
int have_math_longdouble = -1;  /* Math::LongDouble */
int have_math_complex    = -1;  /* Math::Complex    */

MODULE = FFI::Platypus PACKAGE = FFI::Platypus

BOOT:
#ifndef HAVE_IV_IS_64
    PERL_MATH_INT64_LOAD_OR_CROAK;
#endif

int
_have_math_longdouble(value = -2)
    int value
  CODE:
    if(value != -2)
      have_math_longdouble = value;
    RETVAL = have_math_longdouble;
  OUTPUT:
    RETVAL

int
_have_math_complex(value = -2)
    int value
  CODE:
    if(value != -2)
      have_math_complex = value;
    RETVAL = have_math_complex;
  OUTPUT:
    RETVAL

int
_have_type(name)
    const char *name
  CODE:
    RETVAL = !strcmp(name, "string") || ffi_pl_name_to_type(name) != NULL;
  OUTPUT:
    RETVAL


INCLUDE: ../../xs/dl.xs
INCLUDE: ../../xs/Type.xs
INCLUDE: ../../xs/Function.xs
INCLUDE: ../../xs/Declare.xs
INCLUDE: ../../xs/ClosureData.xs
INCLUDE: ../../xs/API.xs
INCLUDE: ../../xs/ABI.xs
INCLUDE: ../../xs/Record.xs
