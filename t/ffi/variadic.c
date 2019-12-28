#include <ffi_platypus.h>
#ifdef FFI_PL_PROBE_VARIADIC
#include <stdio.h>
#include <stdarg.h>
#include "libtest.h"

EXTERN int
variadic_return_arg(int which, ...)
{
  va_list ap;
  int i, val;

  va_start(ap, which);

  for(i=0; i<which; i++)
  {
    val = va_arg(ap, int);
  }

  va_end(ap);

  return val;
}

EXTERN const char *
xprintf(const char *fmt, ...)
{
  va_list ap;
  static char buffer[2046];
  char *bp=buffer;

  va_start(ap, fmt);

  while(*fmt != '\0')
  {
    switch(*fmt)
    {
      case '%':
        {
          char buffer2[64];
          const char *str=buffer2;
          switch(*(++fmt))
          {
            case 'd':
              sprintf(buffer2, "%d", va_arg(ap, int));
              break;
            case 's':
              str = va_arg(ap, char *);
              break;
            default:
              str = "[fmt error]";
              break;
          }
          strcpy(bp, str);
          bp += strlen(str);
        }
        break;

      default:
        *(bp++) = *fmt;
        break;
    }
    fmt++;
  }

  va_end(ap);

  *bp = '\0';

  return buffer;
}

#endif
