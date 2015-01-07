/*
 * DO NOT MODIFY THIS FILE.
 * Thisfile generated from similar file libtest/uint8.c
 * all instances of "int8" have been changed to "int32"
 */
#include "libtest.h"
#include "ffi_platypus.h"

EXTERN uint32_t
uint32_add(uint32_t a, uint32_t b)
{
  return a + b;
}

EXTERN uint32_t*
uint32_inc(uint32_t *a, uint32_t b)
{
  *a += b;
  return a;
}

EXTERN uint32_t
uint32_sum(uint32_t list[10])
{
  int i;
  uint32_t total;
  for(i=0,total=0; i<10; i++)
  {
    total += list[i];
  }
  return total;
}

EXTERN void
uint32_array_inc(uint32_t list[10])
{
  int i;
  for(i=0; i<10; i++)
  {
    list[i]++;
  }
}

EXTERN uint32_t *
uint32_static_array(void)
{
  static uint32_t foo[] = { 1,4,6,8,10,12,14,16,18,20 };
  return foo;
}

