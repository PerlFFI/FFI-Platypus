#include <pthread.h>

int
dlmain(int argc, char *argv[])
{
  pthread_t self = pthread_self();

  if(!pthread_equal(self, pthread_self()))
    return 2;

  return 0;
}
