#include "ffi_platypus.h"

extern uint8_t
uint8_add(uint8_t a, uint8_t b)
{
  return a + b;
}

extern uint8_t*
uint8_inc(uint8_t *a, uint8_t b)
{
  *a += b;
  return a;
}
