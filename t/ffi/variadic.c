#include <ffi_platypus.h>
#ifdef FFI_PL_PROBE_VARIADIC
#include <stdio.h>
#include <stdarg.h>
#include "libtest.h"

EXTERN int
variadic_return_arg(int which, ...)
{
  va_list args;
  va_start(args, which);
  int i, val;

  for(i=0; i<which; i++)
  {
    val = va_arg(args, int);
  }

  va_end(args);

  return val;
}

#endif
