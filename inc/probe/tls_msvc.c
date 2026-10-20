#ifndef _MSC_VER
#error "__declspec(thread) is only reliable with Visual C++"
#endif

static __declspec(thread) char marker;

int
dlmain(int argc, char *argv[])
{
  marker = 1;

  if(marker != 1)
    return 2;

  return 0;
}
