class Foo {
  public:
    int answer() { return 42; };
};

extern "C" int
foo1()
{
  Foo foo;
  return foo.answer();
}
