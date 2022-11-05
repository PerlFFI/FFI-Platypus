#include <ffi_platypus_bundle.h>
#include <string.h>

typedef struct {
  char *name;
  int value;
} foo_t;

foo_t*
foo__new(const char *class_name, const char *name, int value) {
  (void)class_name;
  foo_t *self = malloc( sizeof( foo_t ) );
  self->name = strdup(name);
  self->value = value;
  return self;
}

const char *
foo__name(foo_t *self) {
  return self->name;
}

int
foo__value(foo_t *self) {
  return self->value;
}

void
foo__DESTROY(foo_t *self) {
  free(self->name);
  free(self);
}
