MODULE = FFI::Platypus PACKAGE = FFI::Platypus::Type

BOOT:
{
  HV *ft = get_hv("FFI::Platypus::TypeParser::ffi_type", GV_ADD);
  hv_stores(ft, "void",           newSViv(PTR2IV( &ffi_type_void           )));
  hv_stores(ft, "sint8",          newSViv(PTR2IV( &ffi_type_sint8          )));
  hv_stores(ft, "sint16",         newSViv(PTR2IV( &ffi_type_sint16         )));
  hv_stores(ft, "sint32",         newSViv(PTR2IV( &ffi_type_sint32         )));
  hv_stores(ft, "sint64",         newSViv(PTR2IV( &ffi_type_sint64         )));
  hv_stores(ft, "uint8",          newSViv(PTR2IV( &ffi_type_uint8          )));
  hv_stores(ft, "uint16",         newSViv(PTR2IV( &ffi_type_uint16         )));
  hv_stores(ft, "uint32",         newSViv(PTR2IV( &ffi_type_uint32         )));
  hv_stores(ft, "uint64",         newSViv(PTR2IV( &ffi_type_uint64         )));
  hv_stores(ft, "pointer",        newSViv(PTR2IV( &ffi_type_pointer        )));
  hv_stores(ft, "float",          newSViv(PTR2IV( &ffi_type_float          )));
  hv_stores(ft, "double",         newSViv(PTR2IV( &ffi_type_double         )));
#ifdef FFI_PL_PROBE_LONGDOUBLE
  hv_stores(ft, "longdouble",     newSViv(PTR2IV( &ffi_type_longdouble     )));
#endif
#ifdef FFI_PL_PROBE_COMPLEX
  hv_stores(ft, "complex_float",  newSViv(PTR2IV( &ffi_type_complex_float  )));
  hv_stores(ft, "complex_double", newSViv(PTR2IV( &ffi_type_complex_double )));
#endif
}

SV*
meta(self)
    ffi_pl_type *self
  PREINIT:
    HV *meta;
  CODE:
    meta = ffi_pl_get_type_meta(self);
    RETVAL = newRV_noinc((SV*)meta);
  OUTPUT:
    RETVAL

int
sizeof(self)
    ffi_pl_type *self
  CODE:
    RETVAL = ffi_pl_sizeof(self);
  OUTPUT:
    RETVAL

const char *
kindof(self)
    ffi_pl_type *self
  PREINIT:
    int type_code;
  CODE:
    type_code = self->type_code;

    /* ignore custom asoect */
    if((type_code & FFI_PL_SHAPE_MASK) == FFI_PL_SHAPE_CUSTOM_PERL)
    {
      type_code ^= FFI_PL_SHAPE_CUSTOM_PERL;
    }

    switch(type_code)
    {
      case FFI_PL_TYPE_VOID :
        RETVAL = "void";
        break;

      case FFI_PL_TYPE_SINT8:
      case FFI_PL_TYPE_UINT8:
      case FFI_PL_TYPE_SINT16:
      case FFI_PL_TYPE_UINT16:
      case FFI_PL_TYPE_SINT32:
      case FFI_PL_TYPE_UINT32:
      case FFI_PL_TYPE_SINT64:
      case FFI_PL_TYPE_UINT64:
      case FFI_PL_TYPE_FLOAT:
      case FFI_PL_TYPE_DOUBLE:
      case FFI_PL_TYPE_LONG_DOUBLE:
      case FFI_PL_TYPE_COMPLEX_FLOAT:
      case FFI_PL_TYPE_COMPLEX_DOUBLE:
      case FFI_PL_TYPE_OPAQUE:
        RETVAL = "scalar";
        break;

      case FFI_PL_TYPE_STRING:
        RETVAL = "string";
        break;

      case FFI_PL_TYPE_CLOSURE:
        RETVAL = "closure";
        break;

      case FFI_PL_TYPE_RECORD:
        RETVAL = "record";
        break;

      case FFI_PL_TYPE_RECORD_VALUE:
        RETVAL = "record-value";
        break;

      default:
        switch(type_code & FFI_PL_SHAPE_MASK)
        {
          case FFI_PL_SHAPE_POINTER:
            RETVAL = "pointer";
            break;
          case FFI_PL_SHAPE_ARRAY:
            RETVAL = "array";
            break;
          case FFI_PL_SHAPE_OBJECT:
            RETVAL = "object";
            break;
          default:
            croak("internal error computing type kind (%x)", type_code);
        }
    }
  OUTPUT:
    RETVAL

int
countof(self)
    ffi_pl_type *self
  CODE:
    switch(self->type_code & FFI_PL_SHAPE_MASK)
    {
      case FFI_PL_SHAPE_SCALAR:
      case FFI_PL_SHAPE_POINTER:
      case FFI_PL_SHAPE_CUSTOM_PERL:
      case FFI_PL_SHAPE_OBJECT:
        switch(self->type_code)
        {
          case FFI_PL_TYPE_VOID:
            RETVAL = 0;
            break;
          default:
            RETVAL = 1;
            break;
        }
        break;

      case FFI_PL_SHAPE_ARRAY:
        RETVAL = self->extra[0].array.element_count;
        break;

      default:
        croak("internal error computing type kind (%x)", self->type_code);
    }
  OUTPUT:
    RETVAL

int
type_code(self)
    ffi_pl_type *self
  CODE:
    RETVAL = self->type_code;
  OUTPUT:
    RETVAL

int
is_record(self)
    ffi_pl_type *self
  CODE:
    /* may not need this method anymore */
    RETVAL = self->type_code == FFI_PL_TYPE_RECORD
    ||       self->type_code == (FFI_PL_TYPE_RECORD | FFI_PL_SHAPE_CUSTOM_PERL);
  OUTPUT:
    RETVAL

int
is_record_value(self)
    ffi_pl_type *self
  CODE:
    RETVAL = self->type_code == FFI_PL_TYPE_RECORD_VALUE
    ||       self->type_code == (FFI_PL_TYPE_RECORD_VALUE | FFI_PL_SHAPE_CUSTOM_PERL);
  OUTPUT:
    RETVAL

int
is_customizable(self)
    ffi_pl_type *self
  PREINIT:
    int shape;
    int base;
  CODE:
    shape = self->type_code & FFI_PL_SHAPE_MASK;
    base  = self->type_code & FFI_PL_BASE_MASK;
    RETVAL = shape == FFI_PL_SHAPE_SCALAR
          && (   base == FFI_PL_BASE_SINT
              || base == FFI_PL_BASE_UINT
              || base == FFI_PL_BASE_FLOAT
              || base == FFI_PL_BASE_OPAQUE
              || base == FFI_PL_BASE_RECORD
              || base == (FFI_PL_BASE_RECORD | FFI_PL_BASE_OPAQUE)
             );
  OUTPUT:
    RETVAL

int
is_object_ok(self)
    ffi_pl_type *self
  PREINIT:
    int shape;
    int base;
  CODE:
    shape = self->type_code & FFI_PL_SHAPE_MASK;
    base  = self->type_code & FFI_PL_BASE_MASK;
    RETVAL = shape == FFI_PL_SHAPE_SCALAR
           && (   base == FFI_PL_BASE_SINT
               || base == FFI_PL_BASE_UINT
               || base == FFI_PL_BASE_OPAQUE
              );
  OUTPUT:
    RETVAL

int
is_ro(self)
    ffi_pl_type *self
  CODE:
    RETVAL = self->type_code == FFI_PL_TYPE_STRING     &&
             self->sub_type  == FFI_PL_TYPE_STRING_RO;
  OUTPUT:
    RETVAL

void
DESTROY(self)
    ffi_pl_type *self
  CODE:
    if(self->type_code == FFI_PL_TYPE_CLOSURE)
    {
      if(!PL_dirty)
        Safefree(self->extra[0].closure.ffi_cif.arg_types);
    }
    else if(self->type_code == FFI_PL_TYPE_RECORD
    ||      self->type_code == FFI_PL_TYPE_RECORD_VALUE)
    {
      if(self->extra[0].record.class != NULL)
        free(self->extra[0].record.class);
    }
    else
    {
      switch(self->type_code & FFI_PL_SHAPE_MASK)
      {
        case FFI_PL_SHAPE_CUSTOM_PERL:
          {
            ffi_pl_type_extra_custom_perl *custom;

            custom = &self->extra[0].custom_perl;

            if(custom->perl_to_native != NULL)
              SvREFCNT_dec(custom->perl_to_native);
            if(custom->perl_to_native_post != NULL)
              SvREFCNT_dec(custom->perl_to_native_post);
            if(custom->native_to_perl != NULL)
              SvREFCNT_dec(custom->native_to_perl);
            if(self->extra[0].record.class != NULL)
              free(self->extra[0].record.class);
          }
          break;
        case FFI_PL_SHAPE_OBJECT:
          {
            if(self->extra[0].object.class != NULL)
              free(self->extra[0].object.class);
          }
          break;
        default:
          break;
      }
    }
    if(!PL_dirty)
      Safefree(self);

