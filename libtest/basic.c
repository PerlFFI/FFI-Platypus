#include "ffi_platypus.h"

extern uint8_t
f0(uint8_t input)
{
  return input;
}

extern int
my_atoi(const char *string)
{
  return atoi(string);
}
