int
sum(int *array, int size)
{
  int total,i;
  for(i=0,total=0; i<size; i++)
  {
    total += array[i];
  }
  return total;
}
