#ifndef FFI_PLATYPUS_H
#define FFI_PLATYPUS_H

#include <ffi.h>
#include "ffi_platypus_config.h"
#include "ffi_platypus_probe.h"

#ifdef HAVE_DLFCN_H
#ifndef PERL_OS_WINDOWS
#include <dlfcn.h>
#endif
#endif
#ifdef HAVE_UNISTD_H
#include <unistd.h>
#endif
#ifdef HAVE_STDLIB_H
#include <stdlib.h>
#endif
#ifdef HAVE_STDDEF_H
#include <stddef.h>
#endif
#ifdef HAVE_STDINT_H
#include <stdint.h>
#endif
#ifdef HAVE_INTTYPES_H
#include <inttypes.h>
#endif
#ifdef HAVE_ALLOCA_H
#include <alloca.h>
#endif
#ifdef HAVE_STRING_H
#include <string.h>
#endif
#ifdef HAVE_COMPLEX_H
#include <complex.h>
#endif

#ifdef __cplusplus
extern "C" {
#endif

#ifndef RTLD_LAZY
#define RTLD_LAZY 0
#endif

#ifdef PERL_OS_WINDOWS

void *windlopen(const char *, int);
const char *windlerror(void);
void *windlsym(void *, const char *);
int windlclose(void *);

#define dlopen(filename, flag) windlopen(filename, flag)
#define dlerror() windlerror()
#define dlsym(handle, symbol) windlsym(handle, symbol)
#define dlclose(handle) windlclose(handle)

#endif

typedef enum _platypus_type {
  FFI_PL_NATIVE = 0,
  FFI_PL_STRING,
  FFI_PL_POINTER,
  FFI_PL_ARRAY,
  FFI_PL_CLOSURE,
  FFI_PL_CUSTOM_PERL,
  FFI_PL_RECORD,
  FFI_PL_EXOTIC_FLOAT
} platypus_type;

typedef enum _platypus_string_type {
  FFI_PL_STRING_RO = 0,
  FFI_PL_STRING_RW,
  FFI_PL_STRING_FIXED
} platypus_string_type;

typedef struct _ffi_pl_type_extra_record {
  size_t size;
  void *stash; /* really a HV* pointing to the package stash, or NULL */
} ffi_pl_type_extra_record;

typedef struct _ffi_pl_type_extra_custom_perl {
  void *perl_to_native;
  void *native_to_perl;
  void *perl_to_native_post;
  int argument_count;
} ffi_pl_type_extra_custom_perl;

typedef struct _ffi_pl_type_extra_array {
  int element_count;
} ffi_pl_type_extra_array;

struct _ffi_pl_type;

typedef struct _ffi_pl_type_extra_closure {
  ffi_cif ffi_cif;
  int flags;
  struct _ffi_pl_type *return_type;
  struct _ffi_pl_type *argument_types[0];
} ffi_pl_type_extra_closure;

typedef struct _ffi_pl_type_extra_string {
  platypus_string_type platypus_string_type;
  size_t size;
} ffi_pl_type_extra_string;

typedef union _ffi_pl_type_extra {
  ffi_pl_type_extra_custom_perl  custom_perl;
  ffi_pl_type_extra_array        array;
  ffi_pl_type_extra_closure      closure;
  ffi_pl_type_extra_record       record;
  ffi_pl_type_extra_string       string;
} ffi_pl_type_extra;

typedef struct _ffi_pl_type {
  ffi_type *ffi_type;
  platypus_type platypus_type;
  ffi_pl_type_extra extra[0];
} ffi_pl_type;

typedef struct _ffi_pl_function {
  void *address;
  void *platypus_sv;  /* really a Perl SV* */
  ffi_cif ffi_cif;
  ffi_pl_type *return_type;
  ffi_pl_type *argument_types[0];
} ffi_pl_function;

typedef struct _ffi_pl_closure {
  ffi_closure *ffi_closure;
  void *function_pointer; /* C function pointer */
  void *coderef;          /* Perl HV* pointing to FFI::Platypus::Closure object */
  ffi_pl_type *type;
} ffi_pl_closure;

typedef const char *ffi_pl_string;

typedef union _ffi_pl_result {
  void       *pointer;
  const char *string;
  int8_t     sint8;
  uint8_t    uint8;
  int8_t     sint8_array[4];
  uint8_t    uint8_array[4];
  int16_t    sint16;
  uint16_t   uint16;
  int16_t    sint16_array[2];
  uint16_t   uint16_array[2];
  int32_t    sint32;
  uint32_t   uint32;
  int64_t    sint64;
  uint64_t   uint64;
  float      xfloat;
  double     xdouble;
#ifdef FFI_PL_PROBE_LONGDOUBLE
  long double longdouble;
#endif
#ifdef FFI_TARGET_HAS_COMPLEX_TYPE
#ifdef SIZEOF_FLOAT_COMPLEX
  float complex complex_float;
#endif
#ifdef SIZEOF_DOUBLE_COMPLEX
  double complex complex_double;
#endif
#endif
} ffi_pl_result;

typedef union _ffi_pl_argument {
  void       *pointer;
  const char *string;
  int8_t     sint8;
  uint8_t    uint8;
  int16_t    sint16;
  uint16_t   uint16;
  int32_t    sint32;
  uint32_t   uint32;
  int64_t    sint64;
  uint64_t   uint64;
  float      xfloat;
  double     xdouble;
} ffi_pl_argument;

typedef struct _ffi_pl_arguments {
  int count;
  int reserved;
  ffi_pl_argument slot[0];
} ffi_pl_arguments;

typedef struct _ffi_pl_record_member {
  int offset;
  int count;
} ffi_pl_record_member;

#define ffi_pl_arguments_count(arguments)                 (arguments->count)
#define ffi_pl_arguments_set_pointer(arguments, i, value) (arguments->slot[i].pointer = value)
#define ffi_pl_arguments_get_pointer(arguments, i)        (arguments->slot[i].pointer)
#define ffi_pl_arguments_set_string(arguments, i, value)  (arguments->slot[i].string  = value)
#define ffi_pl_arguments_get_string(arguments, i)         (arguments->slot[i].string)

#define ffi_pl_arguments_set_sint8(arguments, i, value)   (arguments->slot[i].sint8   = value)
#define ffi_pl_arguments_get_sint8(arguments, i)          (arguments->slot[i].sint8)
#define ffi_pl_arguments_set_uint8(arguments, i, value)   (arguments->slot[i].uint8   = value)
#define ffi_pl_arguments_get_uint8(arguments, i)          (arguments->slot[i].uint8)
#define ffi_pl_arguments_set_sint16(arguments, i, value)  (arguments->slot[i].sint16  = value)
#define ffi_pl_arguments_get_sint16(arguments, i)         (arguments->slot[i].sint16)
#define ffi_pl_arguments_set_uint16(arguments, i, value)  (arguments->slot[i].uint16  = value)
#define ffi_pl_arguments_get_uint16(arguments, i)         (arguments->slot[i].uint16)
#define ffi_pl_arguments_set_sint32(arguments, i, value)  (arguments->slot[i].sint32  = value)
#define ffi_pl_arguments_get_sint32(arguments, i)         (arguments->slot[i].sint32)
#define ffi_pl_arguments_set_uint32(arguments, i, value)  (arguments->slot[i].uint32  = value)
#define ffi_pl_arguments_get_uint32(arguments, i)         (arguments->slot[i].uint32)
#define ffi_pl_arguments_set_sint64(arguments, i, value)  (arguments->slot[i].sint64  = value)
#define ffi_pl_arguments_get_sint64(arguments, i)         (arguments->slot[i].sint64)
#define ffi_pl_arguments_set_uint64(arguments, i, value)  (arguments->slot[i].uint64  = value)
#define ffi_pl_arguments_get_uint64(arguments, i)         (arguments->slot[i].uint64)

#define ffi_pl_arguments_set_float(arguments, i, value)  (arguments->slot[i].xfloat  = value)
#define ffi_pl_arguments_get_float(arguments, i)         (arguments->slot[i].xfloat)
#define ffi_pl_arguments_set_double(arguments, i, value)  (arguments->slot[i].xdouble  = value)
#define ffi_pl_arguments_get_double(arguments, i)         (arguments->slot[i].xdouble)

#define ffi_pl_arguments_pointers(arguments) ((void**)&arguments->slot[arguments->count])

#if defined(_MSC_VER)
#define Newx_or_alloca(ptr, count, type) ptr = _alloca(sizeof(type)*count)
#define Safefree_or_alloca(ptr) 
#define HAVE_ALLOCA 1
#elif defined(HAVE_ALLOCA)
#define Newx_or_alloca(ptr, count, type) ptr = alloca(sizeof(type)*count)
#define Safefree_or_alloca(ptr) 
#else
#define Newx_or_alloca(ptr, count, type) Newx(ptr, count, type)
#define Safefree_or_alloca(ptr) Safefree(ptr)
#endif

ffi_type *ffi_pl_name_to_type(const char *);

#ifdef __cplusplus
}
#endif

extern int have_pm(const char *pm_name);

#endif
