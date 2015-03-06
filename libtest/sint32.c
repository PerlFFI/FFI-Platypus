/*
 * DO NOT MODIFY THIS FILE.
 * Thisfile generated from similar file libtest/sint8.c
 * all instances of "int8" have been changed to "int32"
 */
#include "libtest.h"

EXTERN int32_t
sint32_add(int32_t a, int32_t b)
{
  return a + b;
}

EXTERN int32_t*
sint32_inc(int32_t *a, int32_t b)
{
  static int32_t keeper;
  keeper = *a += b;
  return &keeper;
}

EXTERN int32_t
sint32_sum(int32_t list[10])
{
  int i;
  int32_t total;
  for(i=0,total=0; i<10; i++)
  {
    total += list[i];
  }
  return total;
}

EXTERN int32_t
sint32_sum2(int32_t *list, size_t size)
{
  int i;
  int32_t total;
  for(i=0,total=0; i<size; i++)
  {
    total += list[i];
  }
  return total;
}

EXTERN void
sint32_array_inc(int32_t list[10])
{
  int i;
  for(i=0; i<10; i++)
  {
    list[i]++;
  }
}

EXTERN int32_t *
sint32_static_array(void)
{
  static int32_t foo[] = { -1,2,-3,4,-5,6,-7,8,-9,10 };
  return foo;
}

typedef int32_t (*closure_t)(int32_t);
static closure_t my_closure;

EXTERN void
sint32_set_closure(closure_t closure)
{
  my_closure = closure;
}

EXTERN int32_t
sint32_call_closure(int32_t value)
{
  return my_closure(value);
}
