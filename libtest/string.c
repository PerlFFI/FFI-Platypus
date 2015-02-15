#include "libtest.h"

EXTERN int
string_matches_foobarbaz(const char *value)
{
  return !strcmp(value, "foobarbaz");
}

EXTERN const char *
string_return_foobarbaz(void)
{
  return "foobarbaz";
}

typedef const char *my_string_t;
typedef void (*closure_t)(my_string_t);
static closure_t my_closure;

EXTERN void
string_set_closure(closure_t closure)
{
  my_closure = closure;
}

EXTERN void
string_call_closure(const char *value)
{
  my_closure(value);
}

EXTERN const char *
string_pointer_pointer_get(const char **ptr)
{
  return *ptr;
}

EXTERN void
string_pointer_pointer_set(const char **ptr, const char *value)
{
  *ptr = value;
}

EXTERN char **
string_pointer_pointer_return(char *value)
{
  static char buffer[512];
  static char *tmp;
  if(value != NULL)
  {
    strcpy(buffer, value);
    tmp = buffer;
  }
  else
  {
    tmp = value;
  }
  return &tmp;
}

EXTERN const char *
string_fixed_test(int i)
{
  static char buffer[] = "zero one  two  threefour ";
  return &buffer[i*5];
}

