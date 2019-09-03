#include "ffi_platypus.h"

#if SIZEOF_VOIDP == 4
uint64_t
cast0(void)
{
  return 0LL;
}
#else
void *
cast0(void)
{
  return NULL;
}
#endif

#if SIZEOF_VOIDP == 4
uint64_t
cast1(uint64_t value)
{
  return value;
}
#else
void *
cast1(void *value)
{
  return value;
}
#endif
