MODULE = FFI::Platypus PACKAGE = FFI::Platypus::Declare

SV*
sticky(subref)
    SV *subref
  PROTOTYPE: $
  CODE:
    if(sv_isobject(subref) && sv_derived_from(subref, "FFI::Platypus::Closure"))
      RETVAL = SvREFCNT_inc(SvREFCNT_inc(subref));
    else
      croak("object is not a closure");
  OUTPUT:
    RETVAL
