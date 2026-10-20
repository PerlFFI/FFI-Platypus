static _Thread_local char marker;

int
dlmain(int argc, char *argv[])
{
  marker = 1;

  if(marker != 1)
    return 2;

  return 0;
}
