#include <string.h>
#include <stdlib.h>
#include <stdint.h>

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

typedef uint16_t     WCHAR;
typedef WCHAR*       LPWSTR;
typedef const WCHAR* LPCWSTR;

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

  size = strnlen(olds, max);
  news = malloc(size+1);
  if(news != NULL)
  {
    news[size] = '\0';
    memcpy(news, olds, size);
  }
  return news;
}

EXPORT
size_t
ffi_platypus_memory__strlenW(LPCWSTR s)
{
  size_t len = 0;
  for (; *s; ++len, ++s);
  return len;
}

EXPORT
LPWSTR
ffi_platypus_memory__strcpyW(LPWSTR dst, LPCWSTR src)
{
  while (*src)
    *(dst++) = *(src++);
  *dst = 0;
  return dst;
}

EXPORT
LPWSTR
ffi_platypus_memory__strncpyW(LPWSTR dst, LPCWSTR src, size_t n)
{
  for (; *src && n; --n)
    *(dst++) = *(src++);
  for (; n; --n)
    *(dst++) = 0;
  return dst;
}
