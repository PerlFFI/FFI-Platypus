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

#endif
