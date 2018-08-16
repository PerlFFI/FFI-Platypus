MODULE = FFI::Platypus PACKAGE = FFI::Platypus::Closure

void
sticky(subref)
    SV *subref
  CODE:
    if(sv_isobject(subref) && sv_derived_from(subref, "FFI::Platypus::Closure"))
      SvREFCNT_inc(SvREFCNT_inc(subref));
    else
      croak("object is not a closure");
