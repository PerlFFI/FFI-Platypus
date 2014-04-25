#include <ffi_pl.h>
#include <string.h>

extern EXPORT const char *
copy_string_leak_memory(const char *input)
{
  return strdup(input);
}
