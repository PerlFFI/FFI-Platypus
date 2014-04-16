#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

XS(ffi_function)
{
  dVAR; dXSARGS;
  printf("ffi_function cv = %p\n", cv);
  XSRETURN_EMPTY;
}

MODULE = FFI::Platypus      PACKAGE = FFI::Platypus

void
attach_function(function_name)
    const char *function_name
  CODE:
    CV *function_cv = newXS(function_name, ffi_function, "somedll.dll");
    printf("attach_function cv = %p\n", function_cv);	
