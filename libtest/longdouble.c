#include "libtest.h"
#include "ffi_platypus.h"
#ifdef SIZEOF_LONG_DOUBLE

EXTERN long double
longdouble_add(long double a, long double b)
{
  printf("a = %Lf\n", a);
  printf("b = %Lf\n", b);
  return a + b;
}

EXTERN long double*
longdouble_inc(long double *a, long double b)
{
  static long double keeper;
  keeper = *a += b;
  return &keeper;
}

EXTERN long double
longdouble_sum(long double list[10])
{
  int i;
  long double total;
  for(i=0,total=0; i<10; i++)
  {
    total += list[i];
  }
  return total;
}

EXTERN long double
longdouble_sum2(long double *list, size_t size)
{
  int i;
  long double total;
  for(i=0,total=0; i<size; i++)
  {
    total += list[i];
  }
  return total;
}

EXTERN void
longdouble_array_inc(long double list[10])
{
  int i;
  for(i=0; i<10; i++)
  {
    list[i]++;
  }
}

EXTERN long double *
longdouble_static_array(void)
{
  static long double foo[] = { -5.5, 5.5, -10, 10, -15.5, 15.5, 20, -20, 25.5, -25.5 };
  return foo;
}

typedef long double (*closure_t)(long double);
static closure_t my_closure;

EXTERN void
longdouble_set_closure(closure_t closure)
{
  my_closure = closure;
}

EXTERN long double
longdouble_call_closure(long double value)
{
  return my_closure(value);
}

#endif
