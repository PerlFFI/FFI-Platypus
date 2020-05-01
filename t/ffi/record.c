#include <string.h>
#include "libtest.h"

typedef struct {
  char name[16];
  int32_t value;
} foo_record_t;

EXTERN const char *
foo_get_name(foo_record_t *self)
{
  static char ret[16];
  if(self == NULL)
    return NULL;
  /*
   * TODO: we need to copy the name because the record
   * could fall out of scope before we start processing
   * the return values in ffi_platypus_call.h.  If we
   * can rework that code to delay until after the SV*
   * is created for the return value then we wouldn't
   * need to do this.
   */
  memcpy(ret, self->name, 16);
  return ret;
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
