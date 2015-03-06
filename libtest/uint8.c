#include "libtest.h"

EXTERN uint8_t
uint8_add(uint8_t a, uint8_t b)
{
  return a + b;
}

EXTERN uint8_t*
uint8_inc(uint8_t *a, uint8_t b)
{
  static uint8_t keeper;
  keeper = *a += b;
  return &keeper;
}

EXTERN uint8_t
uint8_sum(uint8_t list[10])
{
  int i;
  uint8_t total;
  for(i=0,total=0; i<10; i++)
  {
    total += list[i];
  }
  return total;
}

EXTERN uint8_t
uint8_sum2(uint8_t *list, size_t size)
{
  int i;
  uint8_t total;
  for(i=0,total=0; i<size; i++)
  {
    total += list[i];
  }
  return total;
}

EXTERN void
uint8_array_inc(uint8_t list[10])
{
  int i;
  for(i=0; i<10; i++)
  {
    list[i]++;
  }
}

EXTERN uint8_t *
uint8_static_array(void)
{
  static uint8_t foo[] = { 1,4,6,8,10,12,14,16,18,20 };
  return foo;
}

typedef uint8_t (*closure_t)(uint8_t);
static closure_t my_closure;

EXTERN void
uint8_set_closure(closure_t closure)
{
  my_closure = closure;
}

EXTERN uint8_t
uint8_call_closure(uint8_t value)
{
  return my_closure(value);
}
