#include <stdlib.h>

int
array_sum(const int *a) {
  int i, sum;
  if(a == NULL)
    return -1;
  for(i=0, sum=0; a[i] != 0; i++)
    sum += a[i];
  return sum;
}
