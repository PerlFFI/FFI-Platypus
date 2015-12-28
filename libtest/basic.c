#include "libtest.h"

EXTERN uint8_t
f0(uint8_t input)
{
  return input;
}

EXTERN int
my_atoi(const char *string)
{
  return atoi(string);
}

EXTERN void
f1(void)
{
}

EXTERN void
f2(int *i)
{
  *i = *i+1;
}
