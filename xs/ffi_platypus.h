#ifndef FFI_PLATYPUS_H
#define FFI_PLATYPUS_H

#include <ffi.h>
#include "ffi_platypus_config.h"

#ifndef HAVE_RTLD_LAZY
#define RTLD_LAZY 0
#endif

#ifndef HAVE_dlopen

void *ffi_platypus_dlopen(const char *filename, int flag);
char *ffi_platypus_dlerror(void);
void *ffi_platypus_dlsym(void *handle, const char *symbol);
int ffi_platypus_dlclose(void *handle);

#define dlopen(filename, flag) ffi_platypus_dlopen(filename, flag)
#define dlerror() ffi_platypus_dlerror()
#define dlsym(handle, symbol) ffi_platypus_dlsym(handle, symbol)
#define dlclose(handle) ffi_platypus_dlclose(handle)

#endif

/*
 * out of the box types:
 * - all the integers/floats you can think of
 * - strings
 * - pointer to integer/float (in)
 * - pointer to integer/float (out)
 * - pointer to integer/float (in/out)
 * - fixed array of integer/float (in)
 * - fixed array of integer/float (out)
 * - fixed array of integer/float (in/out)
 * - buffer (size pointer pair) (in)
 * - buffer (size pointer pair) (out)
 * - buffer (size pointer pair) (in/out)
 * custom types:
 * - translator written in Perl (code ref)
 * - translator written in C (function pointer)
 */

#endif
