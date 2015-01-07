#include "libtest.h"
#include "ffi_platypus.h"

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
