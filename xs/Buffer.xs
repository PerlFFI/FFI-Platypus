MODULE = FFI::Platypus PACKAGE = FFI::Platypus::Buffer

# Stolen from Data::Peek::DGrow



void
grow (sv, size)
    SV     *sv
    IV      size
 
  PROTOTYPE: $$
  PPCODE:
    if (SvROK (sv))
        sv = SvRV (sv);
    if (!SvPOK (sv))
        sv_setpvn (sv, "", 0);
    /* don't need the contents; avoid copying into the new memory */
#if PERL_API_VERSION >= 26
    SvPVCLEAR(sv);
#else
    sv_setpvn (sv, "", 0);
#endif
    SvGROW (sv, size);
    EXTEND (SP, 1);
    mPUSHi (SvLEN (sv));
    /* XS DGrow */
