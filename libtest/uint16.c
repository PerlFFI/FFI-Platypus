/*
 * DO NOT MODIFY THIS FILE.
 * Thisfile generated from similar file libtest/uint8.c
 * all instances of "int8" have been changed to "int16"
 */
#include "ffi_platypus.h"

extern uint16_t
uint16_add(uint16_t a, uint16_t b)
{
  return a + b;
}

extern uint16_t*
uint16_inc(uint16_t *a, uint16_t b)
{
  *a += b;
  return a;
}

extern uint16_t
uint16_sum(uint16_t list[10])
{
  int i;
  uint16_t total;
  for(i=0,total=0; i<10; i++)
  {
    total += list[i];
  }
  return total;
}

extern void
uint16_array_inc(uint16_t list[10])
{
  int i;
  for(i=0; i<10; i++)
  {
    list[i]++;
  }
}

extern uint16_t *
uint16_static_array(void)
{
  static uint16_t foo[] = { 1,4,6,8,10,12,14,16,18,20 };
  return foo;
}

