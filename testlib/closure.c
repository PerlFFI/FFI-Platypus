typedef void (void_function)(void);

void
call_void_function(void_function *f)
{
  f();
}
