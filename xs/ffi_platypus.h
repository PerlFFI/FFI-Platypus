#ifndef FFI_PLATYPUS_H
#define FFI_PLATYPUS_H

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

#endif
