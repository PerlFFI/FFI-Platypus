#include <string.h>
#include <stdlib.h>

/*
 * strdup and strndup are useful, but technically not part of the
 * C standard, and thus may be missing from some environments.
 * If libc provides these functions then it will use them,
 * otherwise it will fallback on these implementations.
 */

#ifdef _MSC_VER
#define EXPORT __declspec(dllexport)
#else
#define EXPORT
#endif

EXPORT
char *
ffi_platypus_memory__strdup(const char *olds)
{
  char *news;
  size_t size;

  size = strlen(olds)+1;
  news = malloc(size);
  if(news != NULL)
  {
    memcpy(news, olds, size);
  }

  return news;
}

EXPORT
char *
ffi_platypus_memory__strndup(const char *olds, size_t max)
{
  char *news;
  size_t size;

#ifdef FFI_PL_PROBE_STRNLEN
  size = strnlen(olds, max);
#else
  for(size=0; size <max && olds[size] != '\0'; size++)
    ;
#endif
  news = malloc(size+1);
  if(news != NULL)
  {
    news[size] = '\0';
    memcpy(news, olds, size);
  }
  return news;
}
