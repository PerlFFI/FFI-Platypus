// This requires C++11 (I believe)
// TODO: support older c++ compilers.
#include <iostream>

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

extern "C" void
not_to_call_just_to_pull_in_the_stdcpp()
{
  std::cout << "Hello There" << std::endl;
}
