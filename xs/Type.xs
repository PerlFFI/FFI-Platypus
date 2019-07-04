MODULE = FFI::Platypus PACKAGE = FFI::Platypus::Type

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

void
DESTROY(self)
    ffi_pl_type *self
  CODE:
    if(self->type_code == FFI_PL_TYPE_CLOSURE)
    {
      if(!PL_dirty)
        Safefree(self->extra[0].closure.ffi_cif.arg_types);
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

