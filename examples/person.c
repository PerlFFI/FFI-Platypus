#include <string.h>
#include <stdlib.h>

typedef struct person_t {
  char *name;
  unsigned int age;
} person_t;

person_t *
person_new(const char *name, unsigned int age) {
  person_t *self = malloc(sizeof(person_t));
  self->name = strdup(name);
  self->age  = age;
}

const char *
person_name(person_t *self) {
  return self->name;
}

unsigned int
person_age(person_t *self) {
  return self->age;
}

void
person_free(person_t *self) {
  free(self->name);
  free(self);
}
