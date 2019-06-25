#include <ffi.h>
#include <stdlib.h>
#include <string.h>

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

ffi_type *
ffi_platypus_record_meta___find_symbol(const char *name)
{
  if(!strcmp(name, "sint8"))
    return &ffi_type_sint8;
  else if(!strcmp(name, "sint16"))
    return &ffi_type_sint16;
  else if(!strcmp(name, "sint32"))
    return &ffi_type_sint32;
  else if(!strcmp(name, "sint64"))
    return &ffi_type_sint64;
  else if(!strcmp(name, "uint8"))
    return &ffi_type_uint8;
  else if(!strcmp(name, "uint16"))
    return &ffi_type_uint16;
  else if(!strcmp(name, "uint32"))
    return &ffi_type_uint32;
  else if(!strcmp(name, "uint64"))
    return &ffi_type_uint64;
  else if(!strcmp(name, "pointer"))
    return &ffi_type_pointer;
  else if(!strcmp(name, "float"))
    return &ffi_type_float;
  else if(!strcmp(name, "double"))
    return &ffi_type_double;
    /*  TODO: longdouble, complex_float, complex_duble, complex_longdouble */
  else
    return NULL;
}
