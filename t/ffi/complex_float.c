#include "libtest.h"
#if SIZEOF_FLOAT_COMPLEX

EXTERN float
complex_float_get_real(float complex f)
{
  return crealf(f);
}

EXTERN float
complex_float_get_imag(float complex f)
{
  return cimagf(f);
}

EXTERN const char *
complex_float_to_string(float complex f)
{
  static char buffer[1024];
  sprintf(buffer, "%g + %g * i", crealf(f), cimagf(f));
  return buffer;
}

EXTERN float
complex_float_ptr_get_real(float complex *f)
{
  return crealf(*f);
}

EXTERN float
complex_float_ptr_get_imag(float complex *f)
{
  return cimagf(*f);
}

EXTERN void
complex_float_ptr_set(float complex *f, float r, float i)
{
  *f = r + i*I;
}

#endif
