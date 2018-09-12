#include "ffi_platypus.h"
#include <stdio.h>

ffi_type *_ffi_type_go_string[3] = {
  &ffi_type_pointer,
#if SIZEOF_SIZE_T == 8
  &ffi_type_sint64,
#else
  &ffi_type_sint32,
#endif
  NULL
};

ffi_type ffi_type_gostring = {
  /* size      */  0,
  /* alignment */  0,
  /* type      */  FFI_TYPE_STRUCT,
  /* elements  */  _ffi_type_go_string,
};

ffi_type *
ffi_pl_type_to_libffi_type(ffi_pl_type *type)
{
  int type_code = type->type_code;
  type_code = type_code & ~(FFI_PL_SHAPE_CUSTOM_PERL | FFI_PL_SHAPE_CUSTOM_NATIVE);
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
    case FFI_PL_TYPE_CLOSURE:
    case FFI_PL_TYPE_RECORD:
      return &ffi_type_pointer;
    case FFI_PL_TYPE_STRING:
      return &ffi_type_pointer;
    case FFI_PL_TYPE_GO_STRING:
      return &ffi_type_gostring;
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

int
ffi_pl_name_to_code(const char *name)
{
  if(!strcmp(name, "void"))
  { return FFI_PL_TYPE_VOID; }
  else if(!strcmp(name, "uint8"))
  { return FFI_PL_TYPE_UINT8; }
  else if(!strcmp(name, "sint8"))
  { return FFI_PL_TYPE_SINT8; }
  else if(!strcmp(name, "uint16"))
  { return FFI_PL_TYPE_UINT16; }
  else if(!strcmp(name, "sint16"))
  { return FFI_PL_TYPE_SINT16; }
  else if(!strcmp(name, "uint32"))
  { return FFI_PL_TYPE_UINT32; }
  else if(!strcmp(name, "sint32"))
  { return FFI_PL_TYPE_SINT32; }
  else if(!strcmp(name, "uint64"))
  { return FFI_PL_TYPE_UINT64; }
  else if(!strcmp(name, "sint64"))
  { return FFI_PL_TYPE_SINT64; }
  else if(!strcmp(name, "float"))
  { return FFI_PL_TYPE_FLOAT; }
  else if(!strcmp(name, "double"))
  { return FFI_PL_TYPE_DOUBLE; }
  else if(!strcmp(name, "opaque") || !strcmp(name, "pointer"))
  { return FFI_PL_TYPE_OPAQUE; }
  else if(!strcmp(name, "string") || !strcmp(name, "@go_string"))
  { return FFI_PL_TYPE_STRING; }
#ifdef FFI_PL_PROBE_LONGDOUBLE
  else if(!strcmp(name, "longdouble"))
  { return FFI_PL_TYPE_LONG_DOUBLE; }
#endif
#if FFI_PL_PROBE_COMPLEX
  else if(!strcmp(name, "complex_float"))
  { return FFI_PL_TYPE_COMPLEX_FLOAT; }
  else if(!strcmp(name, "complex_double"))
  { return FFI_PL_TYPE_COMPLEX_DOUBLE; }
#endif
  else
  { return -1; }
}
