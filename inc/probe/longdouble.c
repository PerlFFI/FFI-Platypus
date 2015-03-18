#include "ffi_platypus.h"

long double
my_long_double(long double a, long double b)
{
  if(a != 1.0L || b != 3.0L)
    exit(2);
  return a+b;
}

int
main(int argc, char *argv[])
{
  ffi_cif cif;
  ffi_type *args[2];
  void *values[2];

  if(&ffi_type_longdouble == &ffi_type_double)
    return 2;

  args[0] = &ffi_type_longdouble;
  args[1] = &ffi_type_longdouble;

  if(ffi_prep_cif(&cif, FFI_DEFAULT_ABI, 2, &ffi_type_longdouble, args) == FFI_OK)
  {
    long double answer;
    long double a = 1.0L;
    long double b = 3.0L;
    values[0] = &a;
    values[1] = &b;
    ffi_call(&cif, (void*) my_long_double, &answer, values);
    if(answer == 4.0L)
      return 0;
  }

  return 2;
}
