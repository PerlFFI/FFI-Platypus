#include "ffi_platypus.h"

long double
my_long_double(long double f)
{
  if(f != 2.0L)
    exit(2);
  return 4.0L;
}

int
main(int argc, char *argv[])
{
  ffi_cif cif;
  ffi_type *args[1];
  void *values[1];

  args[0] = &ffi_type_longdouble;

  if(ffi_prep_cif(&cif, FFI_DEFAULT_ABI, 1, &ffi_type_longdouble, args) == FFI_OK)
  {
    long double answer;
    long double input;
    input = 2.0L;
    values[0] = &input;
    ffi_call(&cif, (void*) my_long_double, &answer, values);
    if(answer == 4.0L)
      return 0;
  }

  return 2;
}
