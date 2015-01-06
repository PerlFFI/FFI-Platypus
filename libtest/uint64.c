/*
 * DO NOT MODIFY THIS FILE.
 * Thisfile generated from similar file libtest/uint8.c
 * all instances of "int8" have been changed to "int64"
 */
#include "ffi_platypus.h"

extern uint64_t
uint64_add(uint64_t a, uint64_t b)
{
  return a + b;
}

extern uint64_t*
uint64_inc(uint64_t *a, uint64_t b)
{
  *a += b;
  return a;
}

extern uint64_t
uint64_sum(uint64_t list[10])
{
  int i;
  uint64_t total;
  for(i=0,total=0; i<10; i++)
  {
    total += list[i];
  }
  return total;
}

extern void
uint64_array_inc(uint64_t list[10])
{
  int i;
  for(i=0; i<10; i++)
  {
    list[i]++;
  }
}

extern uint64_t *
uint64_static_array(void)
{
  static uint64_t foo[] = { 1,4,6,8,10,12,14,16,18,20 };
  return foo;
}

