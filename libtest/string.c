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

typedef const char *my_string_t;
typedef void (*closure_t)(my_string_t);
static closure_t my_closure;

EXTERN void
string_set_closure(closure_t closure)
{
  my_closure = closure;
}

EXTERN void
string_call_closure(my_string_t value)
{
  my_closure(value);
}
