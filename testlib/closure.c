typedef void (void_function)(void);

void
call_void_function(void_function *f)
{
  f();
}

typedef int (int_function)(void);

int
call_int_function(int_function *f)
{
  return f();
}

typedef void *(ptr_function)(void);

void *
call_ptr_function(ptr_function *f)
{
  return f();
}
