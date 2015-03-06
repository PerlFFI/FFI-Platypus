#include "libtest.h"

EXTERN int
memcmp4(void *buf1, size_t n1, void *buf2, size_t n2)
{
  if (n1 != n2)
    return 1;

  return memcmp(buf1, buf2, n1);
}
