#include "ffi_platypus.h"

float
my_float_real(float complex c)
{
  return crealf(c);
}

float
my_float_imag(float complex c)
{
  return cimagf(c);
}

double
my_double_real(double complex c)
{
  return creal(c);
}

double
my_double_imag(double complex c)
{
  return cimag(c);
}

float complex
my_float_complex_ret(float r, float i)
{
  return r + i*I;
}

double complex
my_double_complex_ret(double r, double i)
{
  return r + i*I;
}

int
main(int argc, char *argv[])
{
  ffi_cif cif;
  ffi_type *args[2];
  void *values[2];

  args[0] = &ffi_type_complex_float;

  if(ffi_prep_cif(&cif, FFI_DEFAULT_ABI, 1, &ffi_type_float, args) == FFI_OK)
  {
    float answer;
    float complex input;
    input = 1.0 + 2.0 * I;
    values[0] = &input;
    ffi_call(&cif, (void*) my_float_real, &answer, values);
    /* printf("answer = %g\n", answer); */
    if(answer != 1.0)
      return 2;
    ffi_call(&cif, (void*) my_float_imag, &answer, values);
    /* printf("answer = %g\n", answer); */
    if(answer != 2.0)
      return 2;
  }
  else
  {
    return 2;
  }

  args[0] = &ffi_type_complex_double;

  if(ffi_prep_cif(&cif, FFI_DEFAULT_ABI, 1, &ffi_type_double, args) == FFI_OK)
  {
    double answer;
    double complex input;
    input = 1.0 + 2.0 * I;
    values[0] = &input;
    ffi_call(&cif, (void*) my_double_real, &answer, values);
    /* printf("answer = %g\n", answer); */
    if(answer != 1.0)
      return 2;
    ffi_call(&cif, (void*) my_double_imag, &answer, values);
    /* printf("answer = %g\n", answer); */
    if(answer != 2.0)
      return 2;
  }
  else
  {
    return 2;
  }

  args[0] = &ffi_type_float;
  args[1] = &ffi_type_float;

  if(ffi_prep_cif(&cif, FFI_DEFAULT_ABI, 2, &ffi_type_complex_float, args) == FFI_OK)
  {
    float complex answer;
    float r=1.0, i=2.0;
    values[0] = &r;
    values[1] = &i;
    ffi_call(&cif, (void*) my_float_complex_ret, &answer, values);
    if(creal(answer) != 1.0 || cimag(answer) != 2.0)
      return 2;
  }

  args[0] = &ffi_type_double;
  args[1] = &ffi_type_double;

  if(ffi_prep_cif(&cif, FFI_DEFAULT_ABI, 2, &ffi_type_complex_double, args) == FFI_OK)
  {
    double complex answer;
    double r=1.0, i=2.0;
    values[0] = &r;
    values[1] = &i;
    ffi_call(&cif, (void*) my_double_complex_ret, &answer, values);
    if(creal(answer) != 1.0 || cimag(answer) != 2.0)
      return 2;
  }

  return 0;
}
