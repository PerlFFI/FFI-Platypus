#include "libtest.h"

typedef int (*closure1_t)(void);
typedef int (*closure2_t)(int);
static closure1_t my_closure1;
static closure2_t my_closure2;

EXTERN void
closure_set_closure1(closure1_t closure)
{
  my_closure1 = closure;
}

EXTERN void
closure_set_closure2(closure2_t closure)
{
  my_closure2 = closure;
}

EXTERN int
closure_call_closure1(void)
{
  return my_closure1();
}

EXTERN int
closure_call_closure2(int arg)
{
  return my_closure2(arg);
}
