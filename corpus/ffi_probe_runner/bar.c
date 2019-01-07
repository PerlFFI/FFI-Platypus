#include <stdio.h>

int
dlmain(int argc, char *argv[])
{
  int i;
  printf("argc=%d\n", argc);
  for(i=0;i<argc;i++)
    printf("argv[%d]=%s\n", i, argv[i]);
  fprintf(stderr, "something to std error\n");
  return 0;
}
