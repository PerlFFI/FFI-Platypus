#include "ffi_platypus.h"
#include <stdio.h>

ffi_type *
ffi_pl_type_to_libffi_type(ffi_pl_type *type)
{
  int type_code = type->type_code;
  if((type_code & FFI_PL_SHAPE_MASK) == FFI_PL_SHAPE_CUSTOM_PERL)
    type_code = type_code & ~(FFI_PL_SHAPE_MASK);
  if((type_code & FFI_PL_SHAPE_MASK) == FFI_PL_SHAPE_OBJECT)
    type_code = type_code & ~(FFI_PL_SHAPE_MASK);
  switch(type_code)
  {
    case FFI_PL_TYPE_VOID:
      return &ffi_type_void;
    case FFI_PL_TYPE_SINT8:
      return &ffi_type_sint8;
    case FFI_PL_TYPE_SINT16:
      return &ffi_type_sint16;
    case FFI_PL_TYPE_SINT32:
      return &ffi_type_sint32;
    case FFI_PL_TYPE_SINT64:
      return &ffi_type_sint64;
    case FFI_PL_TYPE_UINT8:
      return &ffi_type_uint8;
    case FFI_PL_TYPE_UINT16:
      return &ffi_type_uint16;
    case FFI_PL_TYPE_UINT32:
      return &ffi_type_uint32;
    case FFI_PL_TYPE_UINT64:
      return &ffi_type_uint64;
    case FFI_PL_TYPE_FLOAT:
      return &ffi_type_float;
    case FFI_PL_TYPE_DOUBLE:
      return &ffi_type_double;
#ifdef FFI_PL_PROBE_LONGDOUBLE
    case FFI_PL_TYPE_LONG_DOUBLE:
      return &ffi_type_longdouble;
#endif
#if FFI_PL_PROBE_COMPLEX
    case FFI_PL_TYPE_COMPLEX_FLOAT:
      return &ffi_type_complex_float;
    case FFI_PL_TYPE_COMPLEX_DOUBLE:
      return &ffi_type_complex_double;
#endif
    case FFI_PL_TYPE_OPAQUE:
    case FFI_PL_TYPE_STRING:
    case FFI_PL_TYPE_CLOSURE:
    case FFI_PL_TYPE_RECORD:
      return &ffi_type_pointer;
    case FFI_PL_TYPE_RECORD_VALUE:
      return type->extra[0].record.ffi_type;
  }
  switch(type_code & (FFI_PL_SHAPE_MASK))
  {
    case FFI_PL_SHAPE_POINTER:
    case FFI_PL_SHAPE_ARRAY:
      return &ffi_type_pointer;
    default:
      fprintf(stderr, "FFI::Platypus: internal error: type = %04x\n", type_code);
      fflush(stderr);
      return NULL;
  }
}
