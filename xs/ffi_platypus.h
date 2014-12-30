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

typedef enum _ffi_tr_type {
  FFI_TR_NONE = 0,
  FFI_TR_XSUB,
  FFI_TR_C
} ffi_tr_type;

typedef struct _ffi_pl_type {
  ffi_type ffi_type;
  ffi_tr_type input_type;
  ffi_tr_type output_type;
  void *input_detail;
  void *output_detail;
} ffi_pl_type;

#endif
