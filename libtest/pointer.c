#include "libtest.h"
#include "ffi_platypus.h"

EXTERN void *
pointer_null(void)
{
  return NULL;
}

EXTERN int
pointer_is_null(void *ptr)
{
  return ptr == NULL;
}
