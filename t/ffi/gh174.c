#include "libtest.h"

EXTERN void
gh174_func1 (void (*callback)())
{
  printf( "Inside func..\n");
  (*callback)();
}
