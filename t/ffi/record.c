#include <string.h>
#include "libtest.h"

typedef struct {
  char name[16];
  int32_t value;
} foo_record_t;

EXTERN const char *
foo_get_name(foo_record_t *self)
{
  if(self == NULL)
    return NULL;
  return self->name;
}

EXTERN const char *
foo_value_get_name(foo_record_t self)
{
  static char name[16];
  strcpy(name, self.name);
  return name;
}

EXTERN int32_t
foo_get_value(foo_record_t *self)
{
  if(self == NULL)
    return 0;
  return self->value;
}

EXTERN int32_t
foo_value_get_value(foo_record_t self)
{
  return self.value;
}

EXTERN foo_record_t *
foo_create(const char *name, int32_t value)
{
  static foo_record_t self;
  int i;

  for(i=0; i<16; i++)
    self.name[i] = '\0';

  strcpy(self.name, name);
  self.value = value;

  return &self;
}

EXTERN foo_record_t
foo_value_create(const char *name, int32_t value)
{
  foo_record_t self;
  int i;

  for(i=0; i<16; i++)
    self.name[i] = '\0';

  strcpy(self.name, name);
  self.value = value;

  return self;
}
