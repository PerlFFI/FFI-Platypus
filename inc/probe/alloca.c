#include "ffi_platypus.h"

int
dlmain(int argc, char *argv[])
{
  void *ptr = alloca(100);

  if(ptr == NULL)
    return 2;

  return 0;
}
