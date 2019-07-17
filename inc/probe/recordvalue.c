#include <ffi.h>
#include <string.h>
#include <stdlib.h>

typedef struct {
  char name[13];
  int value;
} foo_t;

foo_t
get_foo(void)
{
  foo_t self;
  strcpy(self.name, "hello");
  self.value = 42;
  return self;
}

int
dlmain(int argc, char *argv[])
{
  ffi_cif cif;
  ffi_type ffi_type_foo_t;
  int i;
  foo_t foo;

  ffi_type_foo_t.size = ffi_type_foo_t.alignment = 0;
  ffi_type_foo_t.type = FFI_TYPE_STRUCT;
  ffi_type_foo_t.elements = calloc(14, sizeof(ffi_type*));

  for(i=0; i<13; i++)
    ffi_type_foo_t.elements[i] = &ffi_type_sint8;
  ffi_type_foo_t.elements[13] = &ffi_type_sint32;

  if(ffi_prep_cif(&cif, FFI_DEFAULT_ABI, 0, &ffi_type_foo_t, NULL) == FFI_OK)
  {
    ffi_call(&cif, (void*) get_foo, &foo, NULL);
    if(strcmp(foo.name, "hello"))
      return 2;
    if(foo.value != 42)
      return 2;
  }
  else
  {
    return 2;
  }

  return 0;
}
