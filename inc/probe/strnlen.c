#include <string.h>

int
dlmain(int argc, char *arg[])
{
  const char *test = "123456789\0";

  if(strnlen(test, 100) == 9 && strnlen(test, 4) == 4)
    return 0;
  else
    return 2;
}
