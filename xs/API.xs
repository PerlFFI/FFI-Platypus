MODULE = FFI::Platypus PACKAGE = FFI::Platypus::API

int
arguments_count()
  PROTOTYPE:
  PREINIT:
    dMY_CXT;
  CODE:
    if(MY_CXT.current_argv == NULL)
      croak("Not in custom type handler");
    RETVAL = ffi_pl_arguments_count(MY_CXT.current_argv);
  OUTPUT:
    RETVAL

void *
arguments_get_pointer(i)
    int i
  PROTOTYPE: $
  PREINIT:
    dMY_CXT;
  CODE:
    if(MY_CXT.current_argv == NULL)
      croak("Not in custom type handler");
    RETVAL = ffi_pl_arguments_get_pointer(MY_CXT.current_argv, i);
  OUTPUT:
    RETVAL

void
arguments_set_pointer(i, value)
    int i
    void *value
  PROTOTYPE: $$
  PREINIT:
    dMY_CXT;
  CODE:
    if(MY_CXT.current_argv == NULL)
      croak("Not in custom type handler");
    ffi_pl_arguments_set_pointer(MY_CXT.current_argv, i, value);

ffi_pl_string
arguments_get_string(i)
    int i
  PROTOTYPE: $
  PREINIT:
    dMY_CXT;
  CODE:
    if(MY_CXT.current_argv == NULL)
      croak("Not in custom type handler");
    RETVAL = ffi_pl_arguments_get_string(MY_CXT.current_argv, i);
  OUTPUT:
    RETVAL

void
arguments_set_string(i, value)
    int i
    ffi_pl_string value
  PROTOTYPE: $$
  PREINIT:
    dMY_CXT;
  CODE:
    if(MY_CXT.current_argv == NULL)
      croak("Not in custom type handler");
    ffi_pl_arguments_set_string(MY_CXT.current_argv, i, value);

UV
arguments_get_uint8(i)
    int i
  PROTOTYPE: $
  PREINIT:
    dMY_CXT;
  CODE:
    if(MY_CXT.current_argv == NULL)
      croak("Not in custom type handler");
    RETVAL = ffi_pl_arguments_get_uint8(MY_CXT.current_argv, i);
  OUTPUT:
    RETVAL

void
arguments_set_uint8(i, value)
    int i
    UV value
  PROTOTYPE: $$
  PREINIT:
    dMY_CXT;
  CODE:
    if(MY_CXT.current_argv == NULL)
      croak("Not in custom type handler");
    ffi_pl_arguments_set_uint8(MY_CXT.current_argv, i, value);

IV
arguments_get_sint8(i)
    int i
  PROTOTYPE: $
  PREINIT:
    dMY_CXT;
  CODE:
    if(MY_CXT.current_argv == NULL)
      croak("Not in custom type handler");
    RETVAL = ffi_pl_arguments_get_sint8(MY_CXT.current_argv, i);
  OUTPUT:
    RETVAL

void
arguments_set_sint8(i, value)
    int i
    IV value
  PROTOTYPE: $$
  PREINIT:
    dMY_CXT;
  CODE:
    if(MY_CXT.current_argv == NULL)
      croak("Not in custom type handler");
    ffi_pl_arguments_set_sint8(MY_CXT.current_argv, i, value);

float
arguments_get_float(i)
    int i
  PROTOTYPE: $
  PREINIT:
    dMY_CXT;
  CODE:
    if(MY_CXT.current_argv == NULL)
      croak("Not in custom type handler");
    RETVAL = ffi_pl_arguments_get_float(MY_CXT.current_argv, i);
  OUTPUT:
    RETVAL

void
arguments_set_float(i, value)
    int i
    float value
  PROTOTYPE: $$
  PREINIT:
    dMY_CXT;
  CODE:
    if(MY_CXT.current_argv == NULL)
      croak("Not in custom type handler");
    ffi_pl_arguments_set_float(MY_CXT.current_argv, i, value);

double
arguments_get_double(i)
    int i
  PROTOTYPE: $
  PREINIT:
    dMY_CXT;
  CODE:
    if(MY_CXT.current_argv == NULL)
      croak("Not in custom type handler");
    RETVAL = ffi_pl_arguments_get_double(MY_CXT.current_argv, i);
  OUTPUT:
    RETVAL

void
arguments_set_double(i, value)
    int i
    double value
  PROTOTYPE: $$
  PREINIT:
    dMY_CXT;
  CODE:
    if(MY_CXT.current_argv == NULL)
      croak("Not in custom type handler");
    ffi_pl_arguments_set_double(MY_CXT.current_argv, i, value);

UV
arguments_get_uint16(i)
    int i
  PROTOTYPE: $
  PREINIT:
    dMY_CXT;
  CODE:
    if(MY_CXT.current_argv == NULL)
      croak("Not in custom type handler");
    RETVAL = ffi_pl_arguments_get_uint16(MY_CXT.current_argv, i);
  OUTPUT:
    RETVAL

void
arguments_set_uint16(i, value)
    int i
    UV value
  PROTOTYPE: $$
  PREINIT:
    dMY_CXT;
  CODE:
    if(MY_CXT.current_argv == NULL)
      croak("Not in custom type handler");
    ffi_pl_arguments_set_uint16(MY_CXT.current_argv, i, value);

IV
arguments_get_sint16(i)
    int i
  PROTOTYPE: $
  PREINIT:
    dMY_CXT;
  CODE:
    if(MY_CXT.current_argv == NULL)
      croak("Not in custom type handler");
    RETVAL = ffi_pl_arguments_get_sint16(MY_CXT.current_argv, i);
  OUTPUT:
    RETVAL

void
arguments_set_sint16(i, value)
    int i
    IV value
  PROTOTYPE: $$
  PREINIT:
    dMY_CXT;
  CODE:
    if(MY_CXT.current_argv == NULL)
      croak("Not in custom type handler");
    ffi_pl_arguments_set_sint16(MY_CXT.current_argv, i, value);

UV
arguments_get_uint32(i)
    int i
  PROTOTYPE: $
  PREINIT:
    dMY_CXT;
  CODE:
    if(MY_CXT.current_argv == NULL)
      croak("Not in custom type handler");
    RETVAL = ffi_pl_arguments_get_uint32(MY_CXT.current_argv, i);
  OUTPUT:
    RETVAL

void
arguments_set_uint32(i, value)
    int i
    UV value
  PROTOTYPE: $$
  PREINIT:
    dMY_CXT;
  CODE:
    if(MY_CXT.current_argv == NULL)
      croak("Not in custom type handler");
    ffi_pl_arguments_set_uint32(MY_CXT.current_argv, i, value);

IV
arguments_get_sint32(i)
    int i
  PROTOTYPE: $
  PREINIT:
    dMY_CXT;
  CODE:
    if(MY_CXT.current_argv == NULL)
      croak("Not in custom type handler");
    RETVAL = ffi_pl_arguments_get_sint32(MY_CXT.current_argv, i);
  OUTPUT:
    RETVAL

void
arguments_set_sint32(i, value)
    int i
    IV value
  PROTOTYPE: $$
  PREINIT:
    dMY_CXT;
  CODE:
    if(MY_CXT.current_argv == NULL)
      croak("Not in custom type handler");
    ffi_pl_arguments_set_sint32(MY_CXT.current_argv, i, value);

void
arguments_get_uint64(i)
    int i
  PROTOTYPE: $
  PREINIT:
    dMY_CXT;
  CODE:
    if(MY_CXT.current_argv == NULL)
      croak("Not in custom type handler");
#ifdef HAVE_IV_IS_64
    XSRETURN_UV(ffi_pl_arguments_get_uint64(MY_CXT.current_argv, i));
#else
    {
      ST(0) = sv_newmortal();
      sv_setu64(ST(0), ffi_pl_arguments_get_uint64(MY_CXT.current_argv, i));
      XSRETURN(1);
    }
#endif

void
arguments_set_uint64(i, value)
    int i
    SV* value
  PROTOTYPE: $$
  PREINIT:
    dMY_CXT;
  CODE:
    if(MY_CXT.current_argv == NULL)
      croak("Not in custom type handler");
#ifdef HAVE_IV_IS_64
    ffi_pl_arguments_set_uint64(MY_CXT.current_argv, i, SvUV(value));
#else
    ffi_pl_arguments_set_uint64(MY_CXT.current_argv, i, SvU64(value));
#endif

void
arguments_get_sint64(i)
    int i
  PROTOTYPE: $
  PREINIT:
    dMY_CXT;
  CODE:
    if(MY_CXT.current_argv == NULL)
      croak("Not in custom type handler");
#ifdef HAVE_IV_IS_64
    XSRETURN_IV(ffi_pl_arguments_get_sint64(MY_CXT.current_argv, i));
#else
    {
      ST(0) = sv_newmortal();
      sv_setu64(ST(0), ffi_pl_arguments_get_sint64(MY_CXT.current_argv, i));
      XSRETURN(1);
    }
#endif

void
arguments_set_sint64(i, value)
    int i
    SV* value
  PROTOTYPE: $$
  PREINIT:
    dMY_CXT;
  CODE:
    if(MY_CXT.current_argv == NULL)
      croak("Not in custom type handler");
#ifdef HAVE_IV_IS_64
    ffi_pl_arguments_set_sint64(MY_CXT.current_argv, i, SvIV(value));
#else
    ffi_pl_arguments_set_sint64(MY_CXT.current_argv, i, SvI64(value));
#endif

