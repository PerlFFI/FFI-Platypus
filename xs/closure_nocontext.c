/*
 * This file intentionally does not include the Perl headers.  On some
 * platforms (notably Windows) XSUB.h redirects stdio functions through
 * the current Perl interpreter, which is exactly what we do not have
 * when this function gets called.
 */

#include <stdio.h>
#include <stdlib.h>

void
ffi_pl_closure_no_context(void)
{
  fprintf(stderr,
    "FFI::Platypus: a closure was called from a thread that does not have a Perl\n"
    "interpreter.  Closures may only be called from the Perl thread that created\n"
    "them.  See the FFI::Platypus FAQ entry \"Can I call a closure from a thread\n"
    "created by a C library?\" for workarounds.\n"
  );
  fflush(stderr);
  abort();
}
