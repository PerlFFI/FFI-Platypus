#include "ffi_platypus.h"

extern int
string_matches_foobarbaz(const char *value)
{
  return !strcmp(value, "foobarbaz");
}

extern const char *
string_return_foobarbaz(void)
{
  return "foobarbaz";
}
