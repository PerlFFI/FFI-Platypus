#include "ffi_platypus.h"

extern int8_t
sint8_add(int8_t a, int8_t b)
{
  return a + b;
}

extern int8_t*
sint8_inc(int8_t *a, int8_t b)
{
  *a += b;
  return a;
}
