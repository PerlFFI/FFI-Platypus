#include "libtest.h"
#ifdef FFI_PL_PROBE_LONGDOUBLE

EXTERN long double
longdouble_add(long double a, long double b)
{
  return a + b;
}

EXTERN int
longdouble_pointer_test(long double *a, long double *b)
{
  if(*a + *b != 4.0L)
    return 0;
  
  *a = 4.0L;
  *b = 8.0L;
  
  return 1;
}

EXTERN long double *
longdouble_pointer_return_test(long double a)
{
  static long double *keep = NULL;
  if(keep == NULL)
    keep = malloc(sizeof(long double));
  *keep = a;
  return keep;
}

#endif
