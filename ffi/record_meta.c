#include <ffi.h>
#include <stdlib.h>
#include <string.h>

#ifdef _MSC_VER
#define EXPORT __declspec(dllexport)
#else
#define EXPORT
#endif

/* TODO: tis is replicated in ffi_platypus.h, which is bad */
typedef struct _ffi_pl_record_meta_t {
  ffi_type ffi_type;
  int can_return_from_closure;
  ffi_type *elements[0];
} ffi_pl_record_meta_t;

/*
 * Question: this is the documented way of creating a struct type.
 * we already compute the size and alignment for the Perl interface
 * to the members, can we use that instead?
 */

EXPORT
ffi_pl_record_meta_t *
ffi_platypus_record_meta__new(ffi_type *list[], int safe_to_return_from_closure)
{
  int size, i;
  ffi_pl_record_meta_t *t;

  for(size=0; list[size] != NULL; size++)
    ;

  t = malloc(sizeof(ffi_pl_record_meta_t) + sizeof(ffi_type*)*(size+1) );
  if(t == NULL)
    return NULL;

  t->ffi_type.size      = 0;
  t->ffi_type.alignment = 0;
  t->ffi_type.type      = FFI_TYPE_STRUCT;
  t->ffi_type.elements  = (ffi_type**) &t->elements;

  t->can_return_from_closure = safe_to_return_from_closure;


  for(i=0; i<size+1; i++)
  {
    t->elements[i] = list[i];
  }

  return t;
}

EXPORT
ffi_type *
ffi_platypus_record_meta__ffi_type(ffi_pl_record_meta_t *t)
{
  return &t->ffi_type;
}

EXPORT
size_t
ffi_platypus_record_meta__size(ffi_pl_record_meta_t *t)
{
  return t->ffi_type.size;
}

EXPORT
unsigned short
ffi_platypus_record_meta__alignment(ffi_pl_record_meta_t *t)
{
  return t->ffi_type.alignment;
}

EXPORT
ffi_type **
ffi_platypus_record_meta__element_pointers(ffi_pl_record_meta_t *t)
{
  return t->ffi_type.elements;
}

EXPORT
void
ffi_platypus_record_meta__DESTROY(ffi_pl_record_meta_t *t)
{
  free(t);
}

EXPORT
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
