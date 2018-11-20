MODULE = FFI::Platypus PACKAGE = FFI::Platypus::Closure

void
sticky(self)
    SV *self
  CODE:
    if(sv_isobject(self) && sv_derived_from(self, "FFI::Platypus::Closure"))
    {
      SvREFCNT_inc_simple_void_NN(self);
      SvREFCNT_inc_simple_void_NN(self);
    }
    else
      croak("object is not a closure");

void
unstick(self)
    SV *self
  CODE:
    if(sv_isobject(self) && sv_derived_from(self, "FFI::Platypus::Closure"))
    {
      SvREFCNT_dec(self);
      SvREFCNT_dec(self);
    }
    else
      croak("object is not a closure");


U32
_svrefcnt(self)
    SV *self
  CODE:
    /* used in test only */
    if(sv_isobject(self) && sv_derived_from(self, "FFI::Platypus::Closure"))
    {
      RETVAL = SvREFCNT(self);
    }
    else
      croak("object is not a closure");
  OUTPUT:
    RETVAL
