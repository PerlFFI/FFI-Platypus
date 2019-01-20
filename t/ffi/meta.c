#include "libtest.h"

struct mymeta_t {
  int foo;
  char *bar;
};

EXTERN struct mymeta_t*
mymeta_new(int foo, const char *bar)
{
  struct mymeta_t *self;
  self = malloc(sizeof(struct mymeta_t));
  self->foo = foo;
  self->bar = malloc(strlen(bar)+1);
  strcpy(self->bar, bar);
  return self;
}

EXTERN void
mymeta_delete(struct mymeta_t *self)
{
  free(self->bar);
  free(self);
}

EXTERN const char *
mymeta_test(struct mymeta_t *self, int count, const char *baz)
{
  static char buffer[1024];
  sprintf(buffer,
    "foo = %d, bar = %s, baz = %s, count = %d",
    self->foo, self->bar != NULL ? self->bar : "undef", baz != NULL ? baz : "undef", count
  );
  return buffer;
}
