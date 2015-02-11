// On Linux build .so with
// % gcj -fPIC -shared -o libexample.so Example.java

public class Example
{
  public static void print_hello()
  {
    System.out.println("hello world");
  }

  public static int add(int a, int b)
  {
    return a + b;
  }
}
