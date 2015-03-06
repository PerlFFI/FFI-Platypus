/*
 * DO NOT MODIFY THIS FILE.
 * Thisfile generated from similar file libtest/sint8.c
 * all instances of "int8" have been changed to "int16"
 */
#include "libtest.h"

EXTERN int16_t
sint16_add(int16_t a, int16_t b)
{
  return a + b;
}

EXTERN int16_t*
sint16_inc(int16_t *a, int16_t b)
{
  static int16_t keeper;
  keeper = *a += b;
  return &keeper;
}

EXTERN int16_t
sint16_sum(int16_t list[10])
{
  int i;
  int16_t total;
  for(i=0,total=0; i<10; i++)
  {
    total += list[i];
  }
  return total;
}

EXTERN int16_t
sint16_sum2(int16_t *list, size_t size)
{
  int i;
  int16_t total;
  for(i=0,total=0; i<size; i++)
  {
    total += list[i];
  }
  return total;
}

EXTERN void
sint16_array_inc(int16_t list[10])
{
  int i;
  for(i=0; i<10; i++)
  {
    list[i]++;
  }
}

EXTERN int16_t *
sint16_static_array(void)
{
  static int16_t foo[] = { -1,2,-3,4,-5,6,-7,8,-9,10 };
  return foo;
}

typedef int16_t (*closure_t)(int16_t);
static closure_t my_closure;

EXTERN void
sint16_set_closure(closure_t closure)
{
  my_closure = closure;
}

EXTERN int16_t
sint16_call_closure(int16_t value)
{
  return my_closure(value);
}
