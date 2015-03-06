#include "libtest.h"

EXTERN float
float_add(float a, float b)
{
  return a + b;
}

EXTERN float*
float_inc(float *a, float b)
{
  static float keeper;
  keeper = *a += b;
  return &keeper;
}

EXTERN float
float_sum(float list[10])
{
  int i;
  float total;
  for(i=0,total=0; i<10; i++)
  {
    total += list[i];
  }
  return total;
}

EXTERN float
float_sum2(float *list, size_t size)
{
  int i;
  float total;
  for(i=0,total=0; i<size; i++)
  {
    total += list[i];
  }
  return total;
}

EXTERN void
float_array_inc(float list[10])
{
  int i;
  for(i=0; i<10; i++)
  {
    list[i]++;
  }
}

EXTERN float *
float_static_array(void)
{
  static float foo[] = { -5.5, 5.5, -10, 10, -15.5, 15.5, 20, -20, 25.5, -25.5 };
  return foo;
}

typedef float (*closure_t)(float);
static closure_t my_closure;

EXTERN void
float_set_closure(closure_t closure)
{
  my_closure = closure;
}

EXTERN float
float_call_closure(float value)
{
  return my_closure(value);
}
