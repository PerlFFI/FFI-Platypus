#include "libtest.h"

typedef struct _my_struct {
  char x1;
  uint64_t my_uint64;
  char x2;
  uint32_t my_uint32;
  char x3;
  uint16_t my_uint16;
  char x4;
  uint8_t my_uint8;

  char x5;
  int64_t my_sint64;
  char x6;
  int32_t my_sint32;
  char x7;
  int16_t my_sint16;
  char x8;
  int8_t my_sint8;

  char x9;
  float my_float;
  char x10;
  double my_double;

  char x11;
  void *my_opaque;
} my_struct;


EXTERN uint64_t
align_get_uint64(my_struct *my_struct)
{
  return my_struct->my_uint64;
}

EXTERN uint32_t
align_get_uint32(my_struct *my_struct)
{
  return my_struct->my_uint32;
}

EXTERN uint16_t
align_get_uint16(my_struct *my_struct)
{
  return my_struct->my_uint16;
}

EXTERN uint8_t
align_get_uint8(my_struct *my_struct)
{
  return my_struct->my_uint8;
}

EXTERN int64_t
align_get_sint64(my_struct *my_struct)
{
  return my_struct->my_sint64;
}

EXTERN int32_t
align_get_sint32(my_struct *my_struct)
{
  return my_struct->my_sint32;
}

EXTERN int16_t
align_get_sint16(my_struct *my_struct)
{
  return my_struct->my_sint16;
}

EXTERN int8_t
align_get_sint8(my_struct *my_struct)
{
  return my_struct->my_sint8;
}

EXTERN float
align_get_float(my_struct *my_struct)
{
  return my_struct->my_float;
}

EXTERN double
align_get_double(my_struct *my_struct)
{
  return my_struct->my_double;
}

EXTERN void *
align_get_opaque(my_struct *my_struct)
{
  return my_struct->my_opaque;
}
