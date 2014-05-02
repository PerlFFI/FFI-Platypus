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

typedef void (void_function_iiiiiiiiii)(int,int,int,int,int,int,int,int,int,int);

void
call_void_function_iiiiiiiiii(void_function_iiiiiiiiii *f, int i1, int i2, int i3, int i4, int i5, int i6, int i7, int i8, int i9, int i10)
{
  f(i1,i2,i3,i4,i5,i6,i7,i8,i9,i10);
}
