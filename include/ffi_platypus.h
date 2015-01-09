#ifndef FFI_PLATYPUS_H
#define FFI_PLATYPUS_H

#include <ffi.h>
#include "ffi_platypus_config.h"

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
  FFI_PL_FFI = 0,
  FFI_PL_STRING,
  FFI_PL_POINTER,
  FFI_PL_ARRAY,
  FFI_PL_CLOSURE,
  FFI_PL_CUSTOM_PERL,
  FFI_PL_CUSTOM_C
} platypus_type;

typedef struct _ffi_pl_type_extra_custom {
  /*
   * this is used for both FFI_PL_CUSTOM_PERL and FFI_PL_CUSTOM_C
   * for _PERL these point to SV* that are code references
   * for _C these are function pointers.
   */
  void *custom[6];
} ffi_pl_type_extra_custom;

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

typedef union _ffi_pl_type_extra {
  ffi_pl_type_extra_custom  custom;
  ffi_pl_type_extra_array   array;
  ffi_pl_type_extra_closure closure;
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
  void *coderef;          /* Perl CV* pointing to code ref */
  ffi_pl_type *type;
} ffi_pl_closure;

typedef const char *ffi_pl_string;

typedef union _ffi_pl_argument {
  void    *pointer;
  char    *string;
  int8_t   sint8;
  uint8_t  uint8;
  int16_t  sint16;
  uint16_t uint16;
  int32_t  sint32;
  uint32_t uint32;
  int64_t  sint64;
  uint64_t uint64;
  float    xfloat;
  double   xdouble;
} ffi_pl_argument;

typedef struct _ffi_pl_arguments {
  int count;
  ffi_pl_argument slot[0];
} ffi_pl_arguments;

#define ffi_pl_arguments_count(arguments)                 (arguments->count)
#define ffi_pl_arguments_set_pointer(arguments, i, value) (arguments->slot[i].pointer = value)
#define ffi_pl_arguments_get_pointer(arguments, i)        (arguments->slot[i].pointer)
#define ffi_pl_arguments_set_string(arguments, i, value)  (arguments->slot[i].string  = value)

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

#define ffi_pl_arguments_pointers(arguments) ((void**)&arguments->slot[arguments->count])

#ifdef HAVE_ALLOCA
#define Newx_or_alloca(ptr, type) ptr = alloca(sizeof(type))
#else
#define Newx_or_alloca(ptr, type) Newx(ptr, 1, type)
#endif

#endif
