class Foo2 {
  public:
    const char *answer() { return "42"; };
};

extern "C" const char *
foo2()
{
  Foo2 foo;
  return foo.answer();
}
