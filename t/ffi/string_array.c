#include "libtest.h"
#include <string.h>

EXTERN const char *
get_string_from_array(const char **array, int index)
{
  static char buffer[512];
  if(array[index] == NULL)
    return NULL;
  strcpy(buffer, array[index]);
  return buffer;
}

EXTERN const char **
onetwothree3()
{
  static char *buffer[4] = {
    "one",
    "two",
    "three"
  };
  return (const char **) buffer;
}

EXTERN const char **
onetwothree4()
{
  static char *buffer[4] = {
    "one",
    "two",
    "three",
    NULL
  };
  return (const char **) buffer;
}

EXTERN const char **
onenullthree3()
{
  static char *buffer[3] = {
    "one",
    NULL,
    "three"
  };
  return (const char **) buffer;
}

EXTERN const char **
ptrnull()
{
  static char *buffer[1] = {
    NULL
  };
  return (const char **) buffer;
}

EXTERN void
string_array_arg_update(char **arg)
{
  arg[0] = "one";
  arg[1] = "two";
}
