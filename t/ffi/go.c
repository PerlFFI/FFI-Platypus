#include "libtest.h"

typedef struct _go_string {
  const char *p;
  ptrdiff_t n;
} go_string;

EXTERN go_string go_null_string()
{
  go_string null = { NULL, 0 };
  return null;
}

EXTERN go_string go_some_string()
{
  go_string some_string = { "some\0string", 11 };
  return some_string; 
}
