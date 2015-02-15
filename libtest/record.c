#include "libtest.h"

typedef struct {
  const char name[16];
  int32_t value;
} foo_record_t;

EXTERN const char *
foo_get_name(foo_record_t *self)
{
  if(self == NULL)
    return NULL;
  return self->name;
}

EXTERN int32_t
foo_get_value(foo_record_t *self)
{
  if(self == NULL)
    return 0;
  return self->value;
}

EXTERN foo_record_t *
foo_create(const char *name, int32_t value)
{
  static foo_record_t myfoo;
  
  strcpy((char*)myfoo.name, name);
  myfoo.value = value;
  
  return &myfoo;
}
