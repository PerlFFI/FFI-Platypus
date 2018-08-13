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

EXTERN int
longdouble_array_test(long double *a, int n)
{
  long double sum;
  int i;
  int ret;

  for(sum=0.0,i=0; i < n; i++)
  {
    sum += a[i];
  }

  if(sum == 100.00)
    ret = 1;
  else
    ret = 0;

  for(i=0; i < n; i++)
    a[i] = (long double) i+1;

  return ret;
}

EXTERN long double *
longdouble_array_return_test()
{
  static long double keep[3] = { 1.0, 2.0, 3.0 };
  return keep;
}

#endif
