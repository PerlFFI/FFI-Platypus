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

typedef int *(int_ptr_function)(void);

int
call_int_ptr_function(int_ptr_function *f)
{
  int *ptr;
  ptr = f();
  return *ptr;
}

typedef void *(ptr_function)(void);

void *
call_ptr_function(ptr_function *f)
{
  return f();
}
