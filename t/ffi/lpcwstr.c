#include "libtest.h"
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

typedef uint16_t     WCHAR;
typedef WCHAR*       LPWSTR;
typedef const WCHAR* LPCWSTR;

static size_t
strlenW(LPCWSTR s)
{
  size_t len = 0;
  for (; *s; ++len, ++s);
  return len;
}


EXTERN int
lpcwstr_len(LPCWSTR s)
{
  if(s == NULL)
    return -1;
  int len = 0;
  for (; *s; ++len, ++s);
  return len;
}

EXTERN LPCWSTR
lpcwstr_doubler_static(LPCWSTR s)
{
  static WCHAR buffer[512];
  if(s == NULL)
    return NULL;
  size_t len = strlenW(s);
  if(len >= 512)
    return NULL;
  memcpy(buffer,     s, len*sizeof(WCHAR));
  memcpy(buffer+len, s, len*sizeof(WCHAR));
  buffer[len*2] = 0;
  return buffer;
}

EXTERN LPWSTR
lpcwstr_copy_arg(LPWSTR dst, LPCWSTR src, size_t n)
{
  size_t len = strlenW(src);
  if (len+1 > n)
    return NULL;
  memcpy(dst, src, len*sizeof(WCHAR));
  dst[len] = 0;
  return dst;
}

EXTERN LPWSTR
lpcwstr_copy_return(LPCWSTR src)
{
  size_t len = strlenW(src);
  LPWSTR dst = malloc((len+1)*sizeof(WCHAR));
  if (!dst)
    return NULL;
  memcpy(dst, src, len*sizeof(WCHAR));
  dst[len] = 0;
  return dst;
}

EXTERN LPWSTR
lpcwstr_doubler_inplace(LPWSTR s, size_t n)
{
  size_t len = strlenW(s);
  if(len*2+1 > n)
    return NULL;
  memcpy(s+len, s, len*sizeof(WCHAR));
  s[len*2] = 0;
  return s;
}
