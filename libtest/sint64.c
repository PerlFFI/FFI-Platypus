/*
 * DO NOT MODIFY THIS FILE.
 * Thisfile generated from similar file libtest/sint8.c
 * all instances of "int8" have been changed to "int64"
 */
#include "libtest.h"

EXTERN int64_t
sint64_add(int64_t a, int64_t b)
{
  return a + b;
}

EXTERN int64_t*
sint64_inc(int64_t *a, int64_t b)
{
  static int64_t keeper;
  keeper = *a += b;
  return &keeper;
}

EXTERN int64_t
sint64_sum(int64_t list[10])
{
  int i;
  int64_t total;
  for(i=0,total=0; i<10; i++)
  {
    total += list[i];
  }
  return total;
}

EXTERN int64_t
sint64_sum2(int64_t *list, size_t size)
{
  int i;
  int64_t total;
  for(i=0,total=0; i<size; i++)
  {
    total += list[i];
  }
  return total;
}

EXTERN void
sint64_array_inc(int64_t list[10])
{
  int i;
  for(i=0; i<10; i++)
  {
    list[i]++;
  }
}

EXTERN int64_t *
sint64_static_array(void)
{
  static int64_t foo[] = { -1,2,-3,4,-5,6,-7,8,-9,10 };
  return foo;
}

typedef int64_t (*closure_t)(int64_t);
static closure_t my_closure;

EXTERN void
sint64_set_closure(closure_t closure)
{
  my_closure = closure;
}

EXTERN int64_t
sint64_call_closure(int64_t value)
{
  return my_closure(value);
}
