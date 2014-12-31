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

typedef enum _platypus_type {
  FFI_PL_FFI = 0,
  FFI_PL_STR,
  FFI_PL_CUSTOM
} platypus_type;

typedef struct _ffi_pl_type {
  ffi_type *ffi_type;
  platypus_type platypus_type;
  void *arg_ffi2pl;
  void *arg_pl2ffi;
  void *ret_ffi2pl;
  void *ret_pl2ffi;
} ffi_pl_type;

#endif
