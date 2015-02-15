#include "libtest.h"

typedef struct {
  char mess_up_alignment;
  const char value[10];
} foo_t;

EXTERN const char *
align_fixed_get_value(foo_t *foo)
{
  return foo->value;
}
