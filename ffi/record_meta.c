#include <ffi.h>
#include <stdlib.h>

typedef struct meta_t {
  ffi_type top;
  ffi_type *elements[0];
} meta_t;

/*
 * Question: this is the documented way of creating a struct type.
 * we already compute the size and alignment for the Perl interface
 * to the members, can we use that instead?
 */

meta_t *
ffi_platypus_record_meta__new(ffi_type *list[])
{
  int size, i;
  meta_t *t;

  for(size=0; list[size] != NULL; size++)
    ;

  t = malloc(sizeof(meta_t) + sizeof(ffi_type*)*(size+1) );
  if(t == NULL)
    return NULL;

  t->top.size      = 0;
  t->top.alignment = 0;
  t->top.type      = FFI_TYPE_STRUCT;
  t->top.elements  = &t->elements;


  for(i=0; i<size+1; i++)
  {
    t->elements[i] = list[i];
  }

  return t;
}

ffi_type *
ffi_platypus_record_meta__ffi_type(meta_t *t)
{
  return &t->top;
}

size_t
ffi_platypus_record_meta__size(meta_t *t)
{
  return t->top.size;
}

unsigned short
ffi_platypus_record_meta__alignment(meta_t *t)
{
  return t->top.alignment;
}

ffi_type *
ffi_platypus_record_meta__element_pointers(meta_t *t)
{
  return t->top.elements;
}

void
ffi_platypus_record_meta__DESTROY(meta_t *t)
{
  free(t);
}
