/*
 * This file intentionally does not include the Perl headers.  On some
 * platforms (notably Windows) XSUB.h redirects stdio functions through
 * the current Perl interpreter, which is exactly what we may not have
 * when ffi_pl_closure_wrong_thread gets called.
 */

#include <stdio.h>
#include <stdlib.h>
#include "ffi_platypus.h"

#if defined FFI_PL_THREAD_ID_TLS

#if defined FFI_PL_PROBE_TLS_C11
static _Thread_local char marker;
#elif defined FFI_PL_PROBE_TLS_GNU
static __thread char marker;
#else
static __declspec(thread) char marker;
#endif

ffi_pl_thread_id
ffi_pl_thread_self(void)
{
  return &marker;
}

#elif defined FFI_PL_THREAD_ID_WIN32

#include <windows.h>

ffi_pl_thread_id
ffi_pl_thread_self(void)
{
  return GetCurrentThreadId();
}

#elif defined FFI_PL_THREAD_ID_PTHREAD

ffi_pl_thread_id
ffi_pl_thread_self(void)
{
  return pthread_self();
}

#endif

#ifdef FFI_PL_HAVE_THREAD_ID

int
ffi_pl_thread_equal(ffi_pl_thread_id a, ffi_pl_thread_id b)
{
#ifdef FFI_PL_THREAD_ID_PTHREAD
  return pthread_equal(a, b);
#else
  return a == b;
#endif
}

#endif

void
ffi_pl_closure_wrong_thread(void)
{
  fprintf(stderr,
    "FFI::Platypus: a closure was called from a thread other than the Perl\n"
    "thread that created it.  Closures may only be called from the Perl thread\n"
    "that created them.  See the FFI::Platypus FAQ entry \"Can I call a closure\n"
    "from a thread created by a C library?\" for workarounds.\n"
  );
  fflush(stderr);
  abort();
}
