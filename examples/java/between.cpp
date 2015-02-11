#include <gcj/cni.h>
#include <java/lang/System.h>
#include <java/io/PrintStream.h>
#include <java/lang/Throwable.h>

extern "C" void
gcj_start()
{
  using namespace java::lang;

  JvCreateJavaVM(NULL);
  JvInitClass(&System::class$);
}

extern "C" void
gcj_end()
{
  JvDetachCurrentThread();
}
