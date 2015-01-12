#include "libtest.h"
#include "ffi_platypus.h"

EXTERN void *
pointer_null(void)
{
  return NULL;
}

EXTERN int
pointer_is_null(void *ptr)
{
  return ptr == NULL;
}

static void *my_pointer;

EXTERN void
pointer_set_my_pointer(void *ptr)
{
  my_pointer = ptr;
}

EXTERN void *
pointer_get_my_pointer(void)
{
  return my_pointer;
}

EXTERN int
pointer_arg_array_in(char *array[3])
{
  return !strcmp(array[0], "one") && !strcmp(array[1], "two") && !strcmp(array[2], "three");
}

EXTERN int
pointer_arg_array_null_in(char *array[3])
{
  return array[0] == NULL && array[1] == NULL && array[2] == NULL;
}

EXTERN void
pointer_arg_array_out(char *array[3])
{
  array[0] = "four";
  array[1] = "five";
  array[2] = "six";
}

EXTERN void
pointer_arg_array_null_out(char *array[3])
{
  array[0] = NULL;
  array[1] = NULL;
  array[2] = NULL;
}

EXTERN char **
pointer_ret_array_out(void)
{
  static char *array[3] = { "seven", "eight", "nine" };
  return array;
}

EXTERN char **
pointer_ret_array_null_out(void)
{
  static char *array[3] = { NULL, NULL, NULL };
  return array;
}
