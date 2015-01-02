#ifndef FFI_PLATYPUS_H
#define FFI_PLATYPUS_H

#include <ffi.h>
#include "ffi_platypus_config.h"

#ifdef HAVE_DLFCN_H
#include <dlfcn.h>
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
  FFI_PL_STRING,
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

typedef struct _ffi_pl_function {
  void *address;
  void *sv;  /* really a Perl SV* */
  ffi_cif ffi_cif;
  ffi_pl_type *return_type;
  ffi_pl_type *argument_types[0];
} ffi_pl_function;

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
#define ffi_pl_arguments_set_string(arguments, i, value)  (arguments->slot[i].string  = value)

#define ffi_pl_arguments_set_sint8(arguments, i, value)   (arguments->slot[i].sint8   = value)
#define ffi_pl_arguments_get_sint8(arguments, i, value)   (arguments->slot[i].sint8)
#define ffi_pl_arguments_set_uint8(arguments, i, value)   (arguments->slot[i].uint8   = value)
#define ffi_pl_arguments_get_uint8(arguments, i, value)   (arguments->slot[i].uint8)
#define ffi_pl_arguments_set_sint16(arguments, i, value)  (arguments->slot[i].sint16  = value)
#define ffi_pl_arguments_get_sint16(arguments, i, value)  (arguments->slot[i].sint16)
#define ffi_pl_arguments_set_uint16(arguments, i, value)  (arguments->slot[i].uint16  = value)
#define ffi_pl_arguments_get_uint16(arguments, i, value)  (arguments->slot[i].uint16)
#define ffi_pl_arguments_set_sint32(arguments, i, value)  (arguments->slot[i].sint32  = value)
#define ffi_pl_arguments_get_sint32(arguments, i, value)  (arguments->slot[i].sint32)
#define ffi_pl_arguments_set_uint32(arguments, i, value)  (arguments->slot[i].uint32  = value)
#define ffi_pl_arguments_get_uint32(arguments, i, value)  (arguments->slot[i].uint32)

#define ffi_pl_arguments_pointers(arguments) ((void**)&arguments->slot[arguments->count])

#endif
