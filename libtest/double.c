/*
 * DO NOT MODIFY THIS FILE.
 * Thisfile generated from similar file libtest/float.c
 * all instances of "float" have been changed to "double"
 */
#include "libtest.h"

EXTERN double
double_add(double a, double b)
{
  return a + b;
}

EXTERN double*
double_inc(double *a, double b)
{
  static double keeper;
  keeper = *a += b;
  return &keeper;
}

EXTERN double
double_sum(double list[10])
{
  int i;
  double total;
  for(i=0,total=0; i<10; i++)
  {
    total += list[i];
  }
  return total;
}

EXTERN double
double_sum2(double *list, size_t size)
{
  int i;
  double total;
  for(i=0,total=0; i<size; i++)
  {
    total += list[i];
  }
  return total;
}

EXTERN void
double_array_inc(double list[10])
{
  int i;
  for(i=0; i<10; i++)
  {
    list[i]++;
  }
}

EXTERN double *
double_static_array(void)
{
  static double foo[] = { -5.5, 5.5, -10, 10, -15.5, 15.5, 20, -20, 25.5, -25.5 };
  return foo;
}

typedef double (*closure_t)(double);
static closure_t my_closure;

EXTERN void
double_set_closure(closure_t closure)
{
  my_closure = closure;
}

EXTERN double
double_call_closure(double value)
{
  return my_closure(value);
}
