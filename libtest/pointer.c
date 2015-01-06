#include "ffi_platypus.h"

void *
pointer_null(void)
{
  return NULL;
}

int
pointer_is_null(void *ptr)
{
  return ptr == NULL;
}
