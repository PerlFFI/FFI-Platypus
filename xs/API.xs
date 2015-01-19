MODULE = FFI::Platypus PACKAGE = FFI::Platypus::API

void
argv()
  PREINIT:
    SV *argv;
  CODE:
    if(current_argv != NULL)
    {
      argv = ST(0) = sv_newmortal();
      sv_setref_pv(argv, "FFI::Platypus::API::ARGV", (void*) current_argv);
      printf("current_argv = %p\n", current_argv);
      XSRETURN(1);
    }
    else
    {
      XSRETURN_EMPTY;
    }

MODULE = FFI::Platypus PACKAGE = FFI::Platypus::API::ARGV

int
count(self)
    ffi_pl_arguments *self
  CODE:
    if(self != current_argv)
      croak("stale argv handle");
    RETVAL = ffi_pl_arguments_count(self);
  OUTPUT:
    RETVAL

void *
get_pointer(self, i)
    ffi_pl_arguments *self
    int i
  CODE:
    if(self != current_argv)
      croak("stale argv handle");
    RETVAL = ffi_pl_arguments_get_pointer(self, i);
  OUTPUT:
    RETVAL

void
set_pointer(self, i, value)
    ffi_pl_arguments *self
    int i
    void *value
  CODE:
    if(self != current_argv)
      croak("stale argv handle");
    printf("current_argv = %p\n", current_argv);
    ffi_pl_arguments_set_pointer(self, i, value);

ffi_pl_string
get_string(self, i)
    ffi_pl_arguments *self
    int i
  CODE:
    if(self != current_argv)
      croak("stale argv handle");
    RETVAL = ffi_pl_arguments_get_string(self, i);
  OUTPUT:
    RETVAL

void
set_string(self, i, value)
    ffi_pl_arguments *self
    int i
    ffi_pl_string value
  CODE:
    if(self != current_argv)
      croak("stale argv handle");
    ffi_pl_arguments_set_string(self, i, value);

UV
get_uint8(self, i)
    ffi_pl_arguments *self
    int i
  CODE:
    if(self != current_argv)
      croak("stale argv handle");
    RETVAL = ffi_pl_arguments_get_uint8(self, i);
  OUTPUT:
    RETVAL

void
set_uint8(self, i, value)
    ffi_pl_arguments *self
    int i
    UV value
  CODE:
    if(self != current_argv)
      croak("stale argv handle");
    ffi_pl_arguments_set_uint8(self, i, value);

IV
get_sint8(self, i)
    ffi_pl_arguments *self
    int i
  CODE:
    if(self != current_argv)
      croak("stale argv handle");
    RETVAL = ffi_pl_arguments_get_sint8(self, i);
  OUTPUT:
    RETVAL

void
set_sint8(self, i, value)
    ffi_pl_arguments *self
    int i
    IV value
  CODE:
    if(self != current_argv)
      croak("stale argv handle");
    ffi_pl_arguments_set_sint8(self, i, value);

float
get_float(self, i)
    ffi_pl_arguments *self
    int i
  CODE:
    if(self != current_argv)
      croak("stale argv handle");
    RETVAL = ffi_pl_arguments_get_float(self, i);
  OUTPUT:
    RETVAL

void
set_float(self, i, value)
    ffi_pl_arguments *self
    int i
    float value
  CODE:
    if(self != current_argv)
      croak("stale argv handle");
    ffi_pl_arguments_set_float(self, i, value);

UV
get_uint16(self, i)
    ffi_pl_arguments *self
    int i
  CODE:
    if(self != current_argv)
      croak("stale argv handle");
    RETVAL = ffi_pl_arguments_get_uint16(self, i);
  OUTPUT:
    RETVAL

void
set_uint16(self, i, value)
    ffi_pl_arguments *self
    int i
    UV value
  CODE:
    if(self != current_argv)
      croak("stale argv handle");
    ffi_pl_arguments_set_uint16(self, i, value);

IV
get_sint16(self, i)
    ffi_pl_arguments *self
    int i
  CODE:
    if(self != current_argv)
      croak("stale argv handle");
    RETVAL = ffi_pl_arguments_get_sint16(self, i);
  OUTPUT:
    RETVAL

void
set_sint16(self, i, value)
    ffi_pl_arguments *self
    int i
    IV value
  CODE:
    if(self != current_argv)
      croak("stale argv handle");
    ffi_pl_arguments_set_sint16(self, i, value);

UV
get_uint32(self, i)
    ffi_pl_arguments *self
    int i
  CODE:
    if(self != current_argv)
      croak("stale argv handle");
    RETVAL = ffi_pl_arguments_get_uint32(self, i);
  OUTPUT:
    RETVAL

void
set_uint32(self, i, value)
    ffi_pl_arguments *self
    int i
    UV value
  CODE:
    if(self != current_argv)
      croak("stale argv handle");
    ffi_pl_arguments_set_uint32(self, i, value);

IV
get_sint32(self, i)
    ffi_pl_arguments *self
    int i
  CODE:
    if(self != current_argv)
      croak("stale argv handle");
    RETVAL = ffi_pl_arguments_get_sint32(self, i);
  OUTPUT:
    RETVAL

void
set_sint32(self, i, value)
    ffi_pl_arguments *self
    int i
    IV value
  CODE:
    if(self != current_argv)
      croak("stale argv handle");
    ffi_pl_arguments_set_sint32(self, i, value);

