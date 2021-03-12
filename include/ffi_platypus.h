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
#ifdef HAVE_COMPLEX_H
#include <complex.h>
#endif

#ifdef __cplusplus
extern "C" {
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

typedef enum _ffi_pl_type_code {

  /*
   * the first three bits represent the
   * native unit size for each type.
   */
  FFI_PL_SIZE_0        = 0x0000,
  FFI_PL_SIZE_8        = 0x0001,
  FFI_PL_SIZE_16       = 0x0002,
  FFI_PL_SIZE_32       = 0x0003,
  FFI_PL_SIZE_64       = 0x0004,
  FFI_PL_SIZE_128      = 0x0005,
  FFI_PL_SIZE_256      = 0x0006,
  FFI_PL_SIZE_512      = 0x0007,
#if SIZEOF_VOIDP == 4
  FFI_PL_SIZE_PTR      = FFI_PL_SIZE_32,
#elif SIZEOF_VOIDP == 8
  FFI_PL_SIZE_PTR      = FFI_PL_SIZE_64,
#else
#error "strange pointer size"
#endif
  FFI_PL_SIZE_MASK     = 0x0007,

  /*
   * The next nine bits represent the type:
   * basics: void, integer, float, complex
   *
   * opaque is a pointer to something, a void*
   *
   * string is a pointer to a null terminated string
   * (a c string, basically)
   *
   * closure is a pointer to a function, usually a
   * Perl function, enclosed within a FFI::Platypus::Closure
   *
   * record is a fixed bitmap, could be either a struct,
   * or a fixed length string.
   */
  FFI_PL_BASE_VOID     = 0x0008,
  FFI_PL_BASE_SINT     = 0x0010,
  FFI_PL_BASE_UINT     = 0x0020,
  FFI_PL_BASE_FLOAT    = 0x0040,
  FFI_PL_BASE_COMPLEX  = 0x0080,
  FFI_PL_BASE_OPAQUE   = 0x0100,
  FFI_PL_BASE_STRING   = 0x0200,
  FFI_PL_BASE_CLOSURE  = 0x0400,
  FFI_PL_BASE_RECORD   = 0x0800,
  FFI_PL_BASE_MASK     = 0x0ff8,

  /*
   * The shape describes how the data is organized.
   * sclar is a simple value, pointer is usually used
   * for pass by reference, array is a list of objects
   * and custom types allow users to create their own
   * custom types.
   */
  FFI_PL_SHAPE_SCALAR        = 0x0000,
  FFI_PL_SHAPE_POINTER       = 0x1000,
  FFI_PL_SHAPE_ARRAY         = 0x2000,
  FFI_PL_SHAPE_CUSTOM_PERL   = 0x3000,
  FFI_PL_SHAPE_OBJECT        = 0x4000,
  FFI_PL_SHAPE_MASK          = 0xf000,

  /*
   * You can or together the different bit fields above to
   * describe a type.  An int for example (usually signed 32 bit integer)
   * is `FFI_PL_SIZE_32 | FFI_PL_BASE_SINT`.  Not all combinations
   * have meaning, for example `FFI_PL_SIZE_8 | FFI_PL_BASE_FLOAT`
   * is gibberish
   */
  FFI_PL_TYPE_VOID           = FFI_PL_SIZE_0   | FFI_PL_BASE_VOID,
  FFI_PL_TYPE_SINT8          = FFI_PL_SIZE_8   | FFI_PL_BASE_SINT,
  FFI_PL_TYPE_SINT16         = FFI_PL_SIZE_16  | FFI_PL_BASE_SINT,
  FFI_PL_TYPE_SINT32         = FFI_PL_SIZE_32  | FFI_PL_BASE_SINT,
  FFI_PL_TYPE_SINT64         = FFI_PL_SIZE_64  | FFI_PL_BASE_SINT,
  FFI_PL_TYPE_UINT8          = FFI_PL_SIZE_8   | FFI_PL_BASE_UINT,
  FFI_PL_TYPE_UINT16         = FFI_PL_SIZE_16  | FFI_PL_BASE_UINT,
  FFI_PL_TYPE_UINT32         = FFI_PL_SIZE_32  | FFI_PL_BASE_UINT,
  FFI_PL_TYPE_UINT64         = FFI_PL_SIZE_64  | FFI_PL_BASE_UINT,
  FFI_PL_TYPE_FLOAT          = FFI_PL_SIZE_32  | FFI_PL_BASE_FLOAT,
  FFI_PL_TYPE_DOUBLE         = FFI_PL_SIZE_64  | FFI_PL_BASE_FLOAT,
  FFI_PL_TYPE_LONG_DOUBLE    = FFI_PL_SIZE_128 | FFI_PL_BASE_FLOAT,
  FFI_PL_TYPE_COMPLEX_FLOAT  = FFI_PL_SIZE_64  | FFI_PL_BASE_COMPLEX,
  FFI_PL_TYPE_COMPLEX_DOUBLE = FFI_PL_SIZE_128 | FFI_PL_BASE_COMPLEX,

  FFI_PL_TYPE_OPAQUE         = FFI_PL_SIZE_PTR | FFI_PL_BASE_OPAQUE,

  /*
   * These types are passed as pointers, and act like opaque types
   * in terms of sizeof, alignof, etc, but get passed differently.
   */
  FFI_PL_TYPE_STRING         = FFI_PL_TYPE_OPAQUE | FFI_PL_BASE_STRING,
  FFI_PL_TYPE_CLOSURE        = FFI_PL_TYPE_OPAQUE | FFI_PL_BASE_CLOSURE,
  FFI_PL_TYPE_RECORD         = FFI_PL_TYPE_OPAQUE | FFI_PL_BASE_RECORD,
  FFI_PL_TYPE_RECORD_VALUE   = FFI_PL_BASE_RECORD,
} ffi_pl_type_code;

typedef enum _platypus_string_type {
  FFI_PL_TYPE_STRING_RO = 0,
  FFI_PL_TYPE_STRING_RW = 1
} platypus_string_type;

typedef struct _ffi_pl_type_extra_object {
  char *class; /* base class */
} ffi_pl_type_extra_object;

typedef struct _ffi_pl_record_meta_t {
  ffi_type top;
  int can_return_from_closure;
  ffi_type *elements[0];
} ffi_pl_record_meta_t;

typedef struct _ffi_pl_type_extra_record {
  size_t size;
  char *class; /* base class */
  ffi_type *ffi_type;
} ffi_pl_type_extra_record;

typedef struct _ffi_pl_type_extra_custom_perl {
  union {
    ffi_pl_type_extra_record record;
  } ox;
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

typedef union _ffi_pl_type_extra {
  ffi_pl_type_extra_custom_perl  custom_perl;
  ffi_pl_type_extra_array        array;
  ffi_pl_type_extra_closure      closure;
  ffi_pl_type_extra_record       record;
  ffi_pl_type_extra_object       object;
} ffi_pl_type_extra;

typedef struct _ffi_pl_type {
  unsigned short type_code;
  unsigned short sub_type;
  ffi_pl_type_extra extra[0];
} ffi_pl_type;

typedef struct _ffi_pl_function {
  void *address;
  void *platypus_sv;  /* really a Perl SV* */
  int platypus_api;
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
#if defined FFI_PL_PROBE_BIGENDIAN
  int8_t     sint8_array[4];
  uint8_t    uint8_array[4];
#elif defined FFI_PL_PROBE_BIGENDIAN64
  int8_t     sint8_array[8];
  uint8_t    uint8_array[8];
#endif
  int16_t    sint16;
  uint16_t   uint16;
#if defined FFI_PL_PROBE_BIGENDIAN
  int16_t    sint16_array[2];
  uint16_t   uint16_array[2];
#elif defined FFI_PL_PROBE_BIGENDIAN64
  int16_t    sint16_array[4];
  uint16_t   uint16_array[4];
#endif
  int32_t    sint32;
  uint32_t   uint32;
#if defined FFI_PL_PROBE_BIGENDIAN64
  uint32_t   uint32_array[2];
  int32_t    sint32_array[2];
#endif
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

typedef struct _ffi_pl_heap {
  void *_this;
  void *_next;
} ffi_pl_heap;

#define ffi_pl_heap_add(ptr, count, type) { \
  ffi_pl_heap *n;                           \
  Newx(ptr, count, type);                   \
  Newx(n, 1, ffi_pl_heap);                  \
  n->_this = ptr;                           \
  n->_next = (void*) heap;                  \
  heap = n;                                 \
}

#define ffi_pl_heap_add_ptr(ptr) {          \
  ffi_pl_heap *n;                           \
  Newx(n, 1, ffi_pl_heap);                  \
  n->_this = ptr;                           \
  n->_next = (void*) heap;                  \
  heap = n;                                 \
}

#define ffi_pl_heap_free() {                \
  while(heap != NULL)                       \
  {                                         \
    ffi_pl_heap *old = heap;                \
    heap = (ffi_pl_heap *) old->_next;      \
    Safefree(old->_this);                   \
    Safefree(old);                          \
  }                                         \
}

#define ffi_pl_croak                        \
  ffi_pl_heap_free();                       \
  croak

#if defined(_MSC_VER)
#define Newx_or_alloca(ptr, count, type) ptr = _alloca(sizeof(type)*count)
#elif defined(FFI_PL_PROBE_ALLOCA)
#define Newx_or_alloca(ptr, count, type) ptr = alloca(sizeof(type)*count)
#else
#define Newx_or_alloca(ptr, count, type) ffi_pl_heap_add(ptr, count, type)
#endif

ffi_type *ffi_pl_type_to_libffi_type(ffi_pl_type *type);
ffi_pl_type *ffi_pl_type_new(size_t size);

#if SIZEOF_VOIDP == 4
uint64_t cast0(void);
#else
void *cast0(void);
#endif

#if SIZEOF_VOIDP == 4
uint64_t cast1(uint64_t value);
#else
void *cast1(void *value);
#endif

#ifdef __cplusplus
}
#endif

#endif
