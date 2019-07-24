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

EXTERN float complex
complex_float_ret(float r, float i)
{
  return r + i*I;
}

EXTERN float complex *
complex_float_ptr_ret(float r, float i)
{
  static float complex f;
  f = r + i*I;
  return &f;
}

EXTERN float complex
complex_float_array_get(float complex *f, int index)
{
  return f[index];
}

EXTERN void
complex_float_array_set(float complex *f, int index, float r, float i)
{
  f[index] = r + i*I;
}

EXTERN float complex *
complex_float_array_ret(void)
{
  static float complex ret[3];

  ret[0] = 0.0 + 0.0*I;
  ret[1] = 1.0 + 2.0*I;
  ret[2] = 3.0 + 4.0*I;

  return ret;
}

#endif
