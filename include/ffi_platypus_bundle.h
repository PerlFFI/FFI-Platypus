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

typedef void (*set_str_t)    (const char *name, const char *value);
typedef void (*set_sint_t)   (const char *name, int64_t value    );
typedef void (*set_uint_t)   (const char *name, uint64_t value   );
typedef void (*set_double_t) (const char *name, double value     );

typedef struct {
  set_str_t    set_str;
  set_sint_t   set_sint;
  set_uint_t   set_uint;
  set_double_t set_double;
} ffi_platypus_constant_t;

void ffi_pl_bundle_init(const char *, int, void **);
void ffi_pl_bundle_constant(const char *, ffi_platypus_constant_t *);
void ffi_pl_bundle_fini(const char *);

#endif
