#include "libtest.h"

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

EXTERN int
pointer_pointer_is_null(void **ptr)
{
  return *ptr == NULL;
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

EXTERN void
pointer_get_my_pointer_arg(void **ret)
{
  *ret = my_pointer;
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

EXTERN void *
pointer_pointer_pointer_to_pointer(void **pointer_pointer)
{
  return *pointer_pointer;
}

EXTERN void**
pointer_pointer_to_pointer_pointer(void *pointer)
{
  static void *pointer_pointer[1];
  pointer_pointer[0] = pointer;
  return pointer_pointer;
}

typedef void *(*closure_t)(void*);
static closure_t my_closure;

EXTERN void
pointer_set_closure(closure_t closure)
{
  my_closure = closure;
}

EXTERN void*
pointer_call_closure(void *value)
{
  return my_closure(value);
}
