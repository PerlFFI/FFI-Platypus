#include <ffi_pl.h>

extern float EXPORT
pass_thru_float(float input)
{
  return input;
}

extern double EXPORT
pass_thru_double(double input)
{
  return input;
}

extern long double EXPORT
pass_thru_long_double(long double input)
{
  return input;
}
