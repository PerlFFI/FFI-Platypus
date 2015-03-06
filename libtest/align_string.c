#include "libtest.h"

typedef struct {
  char mess_up_alignment;
  const char *value;
} foo_t;

EXTERN const char *
align_string_get_value(foo_t *foo)
{
  return foo->value;
}

EXTERN void
align_string_set_value(foo_t *foo, const char *value)
{
  static char buffer[512];
  if(value != NULL)
  {
    strcpy(buffer, value);
    foo->value = buffer;
  }
  else
  {
    foo->value = NULL;
  }
}
