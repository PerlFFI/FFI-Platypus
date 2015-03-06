/*
 * DO NOT MODIFY THIS FILE.
 * Thisfile generated from similar file libtest/uint8.c
 * all instances of "int8" have been changed to "int64"
 */
#include "libtest.h"

EXTERN uint64_t
uint64_add(uint64_t a, uint64_t b)
{
  return a + b;
}

EXTERN uint64_t*
uint64_inc(uint64_t *a, uint64_t b)
{
  static uint64_t keeper;
  keeper = *a += b;
  return &keeper;
}

EXTERN uint64_t
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

EXTERN uint64_t
uint64_sum2(uint64_t *list, size_t size)
{
  int i;
  uint64_t total;
  for(i=0,total=0; i<size; i++)
  {
    total += list[i];
  }
  return total;
}

EXTERN void
uint64_array_inc(uint64_t list[10])
{
  int i;
  for(i=0; i<10; i++)
  {
    list[i]++;
  }
}

EXTERN uint64_t *
uint64_static_array(void)
{
  static uint64_t foo[] = { 1,4,6,8,10,12,14,16,18,20 };
  return foo;
}

typedef uint64_t (*closure_t)(uint64_t);
static closure_t my_closure;

EXTERN void
uint64_set_closure(closure_t closure)
{
  my_closure = closure;
}

EXTERN uint64_t
uint64_call_closure(uint64_t value)
{
  return my_closure(value);
}
