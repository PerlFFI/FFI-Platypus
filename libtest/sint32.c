/*
 * DO NOT MODIFY THIS FILE.
 * Thisfile generated from similar file libtest/sint8.c
 * all instances of "int8" have been changed to "int32"
 */
#include "ffi_platypus.h"

extern int32_t
sint32_add(int32_t a, int32_t b)
{
  return a + b;
}

extern int32_t*
sint32_inc(int32_t *a, int32_t b)
{
  *a += b;
  return a;
}

extern int32_t
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

extern void
sint32_array_inc(int32_t list[10])
{
  int i;
  for(i=0; i<10; i++)
  {
    list[i]++;
  }
}

extern int32_t *
sint32_static_array(void)
{
  static int32_t foo[] = { -1,2,-3,4,-5,6,-7,8,-9,10 };
  return foo;
}

