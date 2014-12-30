#include <ffi_platypus.h>

#ifndef HAVE_dlopen

#if defined(_WIN32) || defined(__CYGWIN__)

#error "TODO"
/* this simply needs to be ported from the old version of FFI::Platypus */

#else

#error "platform not yet supported"
/* Please file a tickt on this project github's issue tracker.  Thanks! */

#endif

#endif
