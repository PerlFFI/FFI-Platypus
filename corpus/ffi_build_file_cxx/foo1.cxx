class Foo {
  public:
    int answer() { return 42; };
};

int
foo1()
{
  // comment
  Foo foo;
  return foo.answer();
}
