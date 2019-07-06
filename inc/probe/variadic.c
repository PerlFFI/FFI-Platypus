#include <stdio.h>
#include <stdarg.h>
#include <ffi.h>

int
return_arg(int which, ...)
{
  va_list args;
  va_start(args, which);
  int i, val;

  for(i=0; i<which; i++)
  {
    val = va_arg(args, int);
  }

  va_end(args);

  return val;
}

int
basic_test()
{
  int answer;

  answer = return_arg(4,10,20,30,40,50,60,70);

  if(answer != 40)
  {
    /* basic varadic function fail */
    printf("basic answer = %d\n", answer);
    return 2;
  }

  return 0;
}

int
ffi_test()
{
  ffi_cif cif;
  ffi_type *args[8]   = { &ffi_type_sint32, &ffi_type_sint32, &ffi_type_sint32, &ffi_type_sint32, &ffi_type_sint32, &ffi_type_sint32, &ffi_type_sint32, &ffi_type_sint32 };
  int values[8] = { 4,10,20,30,40,50,60,70 };
  void *ptrvalues[8]  = { &values[0], &values[1], &values[2], &values[3], &values[4], &values[5], &values[6], &values[7] };
  int answer = -1;

  if(ffi_prep_cif_var(&cif, FFI_DEFAULT_ABI, 1, 7, &ffi_type_sint32, args) == FFI_OK)
  {
    ffi_call(&cif, (void*) return_arg, &answer, ptrvalues);
    if(answer != 40)
    {
      printf("ffi ansewr = %d\n", answer);
      return 2;
    }
    else
    {
      return 0;
    }
  }
  else
  {
    return 2;
  }
}

int
dlmain(int argc, char *argv[])
{
  if(basic_test())
    return 2;
  if(ffi_test())
    return 2;
  return 0;
}
