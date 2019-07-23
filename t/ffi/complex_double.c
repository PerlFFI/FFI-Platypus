#include "libtest.h"
#if SIZEOF_DOUBLE_COMPLEX

EXTERN double
complex_double_get_real(double complex f)
{
  return creal(f);
}

EXTERN double
complex_double_get_imag(double complex f)
{
  return cimag(f);
}

EXTERN const char *
complex_double_to_string(double complex f)
{
  static char buffer[1024];
  sprintf(buffer, "%g + %g * i", creal(f), cimag(f));
  return buffer;
}

EXTERN double
complex_double_ptr_get_real(double complex *f)
{
  return crealf(*f);
}

EXTERN double
complex_double_ptr_get_imag(double complex *f)
{
  return cimagf(*f);
}

EXTERN void
complex_double_ptr_set(double complex *f, double r, double i)
{
  *f = r + i*I;
}

EXTERN double complex
complex_double_ret(double r, double i)
{
  return r + i*I;
}

EXTERN double complex *
complex_double_ptr_ret(double r, double i)
{
  static double complex f;
  f = r + i*I;
  return &f;
}

EXTERN double complex
complex_double_array_get(double complex *f, int i)
{
  return f[i];
}

#endif
