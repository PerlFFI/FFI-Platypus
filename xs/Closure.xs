MODULE = FFI::Platypus PACKAGE = FFI::Platypus::Closure

void
_sticky(self)
    SV *self
  CODE:
    if(sv_isobject(self) && sv_derived_from(self, "FFI::Platypus::Closure"))
    {
      SvREFCNT_inc_simple_void_NN(SvRV(self));
      SvREFCNT_inc_simple_void_NN(SvRV(self));
    }
    else
      croak("object is not a closure");

void
_unstick(self)
    SV *self
  CODE:
    if(sv_isobject(self) && sv_derived_from(self, "FFI::Platypus::Closure"))
    {
      SvREFCNT_dec(SvRV(self));
      SvREFCNT_dec(SvRV(self));
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
      RETVAL = SvREFCNT(SvRV(self));
    }
    else
      croak("object is not a closure");
  OUTPUT:
    RETVAL
