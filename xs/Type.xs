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
    RETVAL = self->type_code == FFI_PL_TYPE_RECORD;
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
    else if(self->type_code == FFI_PL_TYPE_RECORD_VALUE)
    {
      Safefree(self->extra[0].record_value.class);
    }
    else if((self->type_code & FFI_PL_SHAPE_MASK) == FFI_PL_SHAPE_CUSTOM_PERL)
    {
      ffi_pl_type_extra_custom_perl *custom;

      custom = &self->extra[0].custom_perl;

      if(custom->perl_to_native != NULL)
        SvREFCNT_dec(custom->perl_to_native);
      if(custom->perl_to_native_post != NULL)
        SvREFCNT_dec(custom->perl_to_native_post);
      if(custom->native_to_perl != NULL)
        SvREFCNT_dec(custom->native_to_perl);
    }
    if(!PL_dirty)
      Safefree(self);

