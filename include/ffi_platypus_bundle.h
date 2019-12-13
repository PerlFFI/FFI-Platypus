#ifndef FFI_PLATYPUS_BUNDLE_H
#define FFI_PLATYPUS_BUNDLE_H

#include "ffi_platypus_config.h"

#ifdef HAVE_STDDEF_H
#include <stddef.h>
#endif
#ifdef HAVE_STDINT_H
#include <stdint.h>
#endif
#ifdef HAVE_STDLIB_H
#include <stdlib.h>
#endif

typedef struct {
  void (*set_str)    (const char *name, const char *value);
  void (*set_sint)   (const char *name, int64_t value    );
  void (*set_uint)   (const char *name, uint64_t value   );
  void (*set_double) (const char *name, double value     );
} ffi_platypus_constant_t;

#ifdef _MSC_VER
#define EXPORT __declspec(dllexport)
#else
#define EXPORT
#endif

EXPORT void ffi_pl_bundle_init(const char *, int, void **);
EXPORT void ffi_pl_bundle_constant(const char *, ffi_platypus_constant_t *);
EXPORT void ffi_pl_bundle_fini(const char *);

#endif
