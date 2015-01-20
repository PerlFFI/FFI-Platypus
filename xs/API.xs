MODULE = FFI::Platypus PACKAGE = FFI::Platypus::API

int
arguments_count()
  PROTOTYPE:
  CODE:
    if(current_argv == NULL)
      croak("Not in custom type handler");
    RETVAL = ffi_pl_arguments_count(current_argv);
  OUTPUT:
    RETVAL

void *
arguments_get_pointer(i)
    int i
  PROTOTYPE: $
  CODE:
    if(current_argv == NULL)
      croak("Not in custom type handler");
    RETVAL = ffi_pl_arguments_get_pointer(current_argv, i);
  OUTPUT:
    RETVAL

void
arguments_set_pointer(i, value)
    int i
    void *value
  PROTOTYPE: $$
  CODE:
    if(current_argv == NULL)
      croak("Not in custom type handler");
    ffi_pl_arguments_set_pointer(current_argv, i, value);

ffi_pl_string
arguments_get_string(i)
    int i
  PROTOTYPE: $
  CODE:
    if(current_argv == NULL)
      croak("Not in custom type handler");
    RETVAL = ffi_pl_arguments_get_string(current_argv, i);
  OUTPUT:
    RETVAL

void
arguments_set_string(i, value)
    int i
    ffi_pl_string value
  PROTOTYPE: $$
  CODE:
    if(current_argv == NULL)
      croak("Not in custom type handler");
    ffi_pl_arguments_set_string(current_argv, i, value);

UV
arguments_get_uint8(i)
    int i
  PROTOTYPE: $
  CODE:
    if(current_argv == NULL)
      croak("Not in custom type handler");
    RETVAL = ffi_pl_arguments_get_uint8(current_argv, i);
  OUTPUT:
    RETVAL

void
arguments_set_uint8(i, value)
    int i
    UV value
  PROTOTYPE: $$
  CODE:
    if(current_argv == NULL)
      croak("Not in custom type handler");
    ffi_pl_arguments_set_uint8(current_argv, i, value);

IV
arguments_get_sint8(i)
    int i
  PROTOTYPE: $
  CODE:
    if(current_argv == NULL)
      croak("Not in custom type handler");
    RETVAL = ffi_pl_arguments_get_sint8(current_argv, i);
  OUTPUT:
    RETVAL

void
arguments_set_sint8(i, value)
    int i
    IV value
  PROTOTYPE: $$
  CODE:
    if(current_argv == NULL)
      croak("Not in custom type handler");
    ffi_pl_arguments_set_sint8(current_argv, i, value);

float
arguments_get_float(i)
    int i
  PROTOTYPE: $
  CODE:
    if(current_argv == NULL)
      croak("Not in custom type handler");
    RETVAL = ffi_pl_arguments_get_float(current_argv, i);
  OUTPUT:
    RETVAL

void
arguments_set_float(i, value)
    int i
    float value
  PROTOTYPE: $$
  CODE:
    if(current_argv == NULL)
      croak("Not in custom type handler");
    ffi_pl_arguments_set_float(current_argv, i, value);

double
arguments_get_double(i)
    int i
  PROTOTYPE: $
  CODE:
    if(current_argv == NULL)
      croak("Not in custom type handler");
    RETVAL = ffi_pl_arguments_get_double(current_argv, i);
  OUTPUT:
    RETVAL

void
arguments_set_double(i, value)
    int i
    double value
  PROTOTYPE: $$
  CODE:
    if(current_argv == NULL)
      croak("Not in custom type handler");
    ffi_pl_arguments_set_double(current_argv, i, value);

UV
arguments_get_uint16(i)
    int i
  PROTOTYPE: $
  CODE:
    if(current_argv == NULL)
      croak("Not in custom type handler");
    RETVAL = ffi_pl_arguments_get_uint16(current_argv, i);
  OUTPUT:
    RETVAL

void
arguments_set_uint16(i, value)
    int i
    UV value
  PROTOTYPE: $$
  CODE:
    if(current_argv == NULL)
      croak("Not in custom type handler");
    ffi_pl_arguments_set_uint16(current_argv, i, value);

IV
arguments_get_sint16(i)
    int i
  PROTOTYPE: $
  CODE:
    if(current_argv == NULL)
      croak("Not in custom type handler");
    RETVAL = ffi_pl_arguments_get_sint16(current_argv, i);
  OUTPUT:
    RETVAL

void
arguments_set_sint16(i, value)
    int i
    IV value
  PROTOTYPE: $$
  CODE:
    if(current_argv == NULL)
      croak("Not in custom type handler");
    ffi_pl_arguments_set_sint16(current_argv, i, value);

UV
arguments_get_uint32(i)
    int i
  PROTOTYPE: $
  CODE:
    if(current_argv == NULL)
      croak("Not in custom type handler");
    RETVAL = ffi_pl_arguments_get_uint32(current_argv, i);
  OUTPUT:
    RETVAL

void
arguments_set_uint32(i, value)
    int i
    UV value
  PROTOTYPE: $$
  CODE:
    if(current_argv == NULL)
      croak("Not in custom type handler");
    ffi_pl_arguments_set_uint32(current_argv, i, value);

IV
arguments_get_sint32(i)
    int i
  PROTOTYPE: $
  CODE:
    if(current_argv == NULL)
      croak("Not in custom type handler");
    RETVAL = ffi_pl_arguments_get_sint32(current_argv, i);
  OUTPUT:
    RETVAL

void
arguments_set_sint32(i, value)
    int i
    IV value
  PROTOTYPE: $$
  CODE:
    if(current_argv == NULL)
      croak("Not in custom type handler");
    ffi_pl_arguments_set_sint32(current_argv, i, value);

void
arguments_get_uint64(i)
    int i
  PROTOTYPE: $
  CODE:
    if(current_argv == NULL)
      croak("Not in custom type handler");
#ifdef HAVE_IV_IS_64
    XSRETURN_UV(ffi_pl_arguments_get_uint64(current_argv, i));
#else
    {
      ST(0) = sv_newmortal();
      sv_setu64(ST(0), ffi_pl_arguments_get_uint64(current_argv, i));
      XSRETURN(1);
    }
#endif

void
arguments_set_uint64(i, value)
    int i
    SV* value
  PROTOTYPE: $$
  CODE:
    if(current_argv == NULL)
      croak("Not in custom type handler");
#ifdef HAVE_IV_IS_64
    ffi_pl_arguments_set_uint64(current_argv, i, SvUV(value));
#else
    ffi_pl_arguments_set_uint64(current_argv, i, SvU64(value));
#endif

void
arguments_get_sint64(i)
    int i
  PROTOTYPE: $
  CODE:
    if(current_argv == NULL)
      croak("Not in custom type handler");
#ifdef HAVE_IV_IS_64
    XSRETURN_IV(ffi_pl_arguments_get_sint64(current_argv, i));
#else
    {
      ST(0) = sv_newmortal();
      sv_setu64(ST(0), ffi_pl_arguments_get_sint64(current_argv, i));
      XSRETURN(1);
    }
#endif

void
arguments_set_sint64(i, value)
    int i
    SV* value
  PROTOTYPE: $$
  CODE:
    if(current_argv == NULL)
      croak("Not in custom type handler");
#ifdef HAVE_IV_IS_64
    ffi_pl_arguments_set_sint64(current_argv, i, SvIV(value));
#else
    ffi_pl_arguments_set_sint64(current_argv, i, SvI64(value));
#endif

