/*
 * closure.c - on Linux compile with: gcc closure.c -shared -o closure.so -fPIC
 */

#include <stdio.h>

typedef int (*closure_t)(int);
closure_t my_closure = NULL;

void set_closure(closure_t value)
{
  my_closure = value;
}

int call_closure(int value)
{
  if(my_closure != NULL)
    return my_closure(value);
  else
    fprintf(stderr, "closure is NULL\n");
}
