MODULE = FFI::Platypus PACKAGE = FFI::Platypus::Buffer

void
grow (sv, size, ... )
    SV     *sv
    STRLEN      size
 
  PROTOTYPE: $$;$
  PREINIT:
    int clear = 1;  
  PPCODE:
    if ( items > 2 )
        clear = SvIV(ST(2));

    if (SvROK (sv))
        croak("argument error: buffer must be a scalar");
        
    /* if not a string turn it into an empty one, or if clearing is
       requested, reset string length */
    if (!SvPOK (sv) || clear ) {
#     if PERL_API_VERSION >= 26
        SvPVCLEAR(sv);
#else
        sv_setpvn (sv, "", 0);
#endif
    }

    SvGROW (sv, size);
    EXTEND (SP, 1);
    mPUSHi (SvLEN (sv));


STRLEN
set_used_length( sv, size )
    SV     *sv
    STRLEN      size

  PROTOTYPE: $$
  PREINIT:
    STRLEN len;
  CODE:
    if (SvROK (sv))
        croak("argument error: buffer must be a scalar");

    /* add some stringiness if necessary; svCUR_set only works on PV's */
    if (!SvPOK (sv))
        sv_setpvn (sv, "", 0);

    len = SvLEN( sv );
    RETVAL = size > len ? len : size;
    SvCUR_set( sv, RETVAL );
  OUTPUT:
    RETVAL
