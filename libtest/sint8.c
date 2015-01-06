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

extern int8_t
sint8_sum(int8_t list[10])
{
  int i;
  int8_t total;
  for(i=0,total=0; i<10; i++)
  {
    total += list[i];
  }
  return total;
}

extern void
sint8_array_inc(int8_t list[10])
{
  int i;
  for(i=0; i<10; i++)
  {
    list[i]++;
  }
}
