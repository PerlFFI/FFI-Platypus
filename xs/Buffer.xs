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
    SvPVCLEAR(sv);
    SvGROW (sv, size);
    EXTEND (SP, 1);
    mPUSHi (SvLEN (sv));
    /* XS DGrow */
