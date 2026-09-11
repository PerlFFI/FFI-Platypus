MODULE = FFI::Platypus PACKAGE = FFI::Platypus::Buffer

void
window(sv, addr, len = 0, utf8 = 0)
    SV* sv
    void *addr
    size_t len
    IV utf8
  PROTOTYPE: $$;$$
  CODE:
    if(len == 0)
      len = strlen((char*)addr);
    SvUPGRADE(sv, SVt_PV);
    SvPVX(sv) = addr;
    SvCUR_set(sv, len);
    SvLEN_set(sv, 0);
    SvPOK_only(sv);
    SvREADONLY_on(sv);
    if(utf8)
      SvUTF8_on(sv);

void
grow (sv, size, ... )
    SV     *sv
    STRLEN      size

  PROTOTYPE: $$;$
  PREINIT:
    int clear = 1;
    int set_length = 1;

  PPCODE:
    if (SvROK (sv))
        croak("buffer argument must be a scalar");

   if ( items > 2 ) {

       HV* hash = NULL;
       SV* options = ST(2);
       char *key;
       I32 len;
       SV* value;

       if ( SvROK(options) )
           hash = (HV*) SvRV(options);

       if ( !hash || SvTYPE(hash) != SVt_PVHV )
           croak("options argument must be a hash");

       hv_iterinit(hash);
       while( (value = hv_iternextsv(hash, &key, &len)) != NULL ) {

           if      ( 0 == strncmp( key, "clear", len )  ) {
               clear = SvTRUE( value  );
           }
           else if ( 0 == strncmp( key, "set_length", len )  ) {
               set_length = SvTRUE( value );
           }
           else {
               croak("unknown option: %s", key );
           }
       }
   }

    /* if not a string turn it into an empty one, or if clearing is
       requested, reset string length */
    if (!SvPOK (sv) || clear ) {
#if PERL_API_VERSION >= 26
        SvPVCLEAR(sv);
#else
        sv_setpvn (sv, "", 0);
#endif
    }

    SvGROW (sv, size);
    if ( set_length )
      SvCUR_set( sv, size );
    EXTEND (SP, 1);
    mPUSHi (SvLEN (sv));


void
raw_scalar(size)
    STRLEN size

  PROTOTYPE: $
  PREINIT:
    SV *sv;

  PPCODE:
    /* newSV(0) doesn't allocate a buffer at all, so ask for at least one
       byte so that the scalar always has a valid PV to point at */
    sv = newSV(size ? size : 1);
    SvPOK_only(sv);
    SvCUR_set(sv, size);
    SvPVX(sv)[size] = '\0';
    EXTEND(SP, 1);
    PUSHs(sv_2mortal(sv));


STRLEN
set_used_length( sv, size )
    SV     *sv
    STRLEN      size

  PROTOTYPE: $$
  PREINIT:
    STRLEN len;
  CODE:
    if (SvROK (sv))
        croak("buffer argument must be a scalar");

    /* add some stringiness if necessary; svCUR_set only works on PV's */
    if (!SvPOK (sv))
        sv_setpvn (sv, "", 0);

    len = SvLEN( sv );
    RETVAL = size > len ? len : size;
    SvCUR_set( sv, RETVAL );
  OUTPUT:
    RETVAL
