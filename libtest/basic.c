#include "libtest.h"
#include "ffi_platypus.h"

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
