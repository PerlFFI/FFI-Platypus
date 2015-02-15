#include "ffi_platypus.h"

ffi_type *
ffi_pl_name_to_type(const char *name)
{
  if(!strcmp(name, "void"))
  { return &ffi_type_void; }
  else if(!strcmp(name, "uint8"))
  { return &ffi_type_uint8; }
  else if(!strcmp(name, "sint8"))
  { return &ffi_type_sint8; }
  else if(!strcmp(name, "uint16"))
  { return &ffi_type_uint16; }
  else if(!strcmp(name, "sint16"))
  { return &ffi_type_sint16; }
  else if(!strcmp(name, "uint32"))
  { return &ffi_type_uint32; }
  else if(!strcmp(name, "sint32"))
  { return &ffi_type_sint32; }
  else if(!strcmp(name, "uint64"))
  { return &ffi_type_uint64; }
  else if(!strcmp(name, "sint64"))
  { return &ffi_type_sint64; }
  else if(!strcmp(name, "float"))
  { return &ffi_type_float; }
  else if(!strcmp(name, "double"))
  { return &ffi_type_double; }
  else if(!strcmp(name, "longdouble"))
  { return &ffi_type_longdouble; }
  else if(!strcmp(name, "opaque") || !strcmp(name, "pointer"))
  { return &ffi_type_pointer; }
#ifdef SIZEOF_LONG_DOUBLE
  else if(!strcmp(name, "longdouble"))
  { return &ffi_type_longdouble; }
#endif
#if 0
#ifdef FFI_TARGET_HAS_COMPLEX_TYPE
#ifdef SIZEOF_FLOAT_COMPLEX
  else if(!strcmp(name, "complex_float"))
  { return &ffi_type_complex_float; }
#endif
#ifdef SIZEOF_DOUBLE_COMPLEX
  else if(!strcmp(name, "complex_double"))
  { return &ffi_type_complex_double; }
#endif
#endif
#endif
  else
  { return NULL; }
}
