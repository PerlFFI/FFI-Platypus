#include <ffi_pl.h>

extern int EXPORT
integer_pointer_in(int *input)
{
  if(input == NULL)
    return 4242;
  return (*input)+1;
}

extern void EXPORT
integer_pointer_out(int *input)
{
  (*input)++;
}

extern double EXPORT
double_pointer_in(double *input)
{
  if(input == NULL)
    return 12.34;
  return *input;
}

extern void EXPORT
double_pointer_out(double *input)
{
  *input = -(*input);
}

int EXPORT *
int_to_int_ptr(int input)
{
  int *ptr = (int *) malloc(sizeof(int));
  *ptr = input;
  return ptr;
}

double EXPORT *
double_to_double_ptr(double input)
{
  double *ptr = (double *) malloc(sizeof(double));
  *ptr = input;
  return ptr;
}

int *
integer_pointer_ret(int input)
{
  int *tmp = malloc(sizeof(int));
  *tmp = input;
  return tmp;
}

double *
double_pointer_ret(double input)
{
  double *tmp = malloc(sizeof(double));
  *tmp = input;
  return tmp;
}
