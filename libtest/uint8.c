#include "libtest.h"
#include "ffi_platypus.h"

EXTERN uint8_t
uint8_add(uint8_t a, uint8_t b)
{
  return a + b;
}

EXTERN uint8_t*
uint8_inc(uint8_t *a, uint8_t b)
{
  *a += b;
  return a;
}

EXTERN uint8_t
uint8_sum(uint8_t list[10])
{
  int i;
  uint8_t total;
  for(i=0,total=0; i<10; i++)
  {
    total += list[i];
  }
  return total;
}

EXTERN void
uint8_array_inc(uint8_t list[10])
{
  int i;
  for(i=0; i<10; i++)
  {
    list[i]++;
  }
}

EXTERN uint8_t *
uint8_static_array(void)
{
  static uint8_t foo[] = { 1,4,6,8,10,12,14,16,18,20 };
  return foo;
}

