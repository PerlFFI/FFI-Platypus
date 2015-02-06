MODULE = FFI::Platypus PACKAGE = FFI::Platypus::Record

void
_accessor(perl_name, path_name, type, offset)
    const char *perl_name
    ffi_pl_string path_name;
    ffi_pl_type *type
    int offset
  PROTOTYPE: $$$$
  PREINIT:
    ffi_pl_record_member *member;
    CV *cv;
    void *function;
    /* not the correct prototype */
    extern void ffi_pl_record_accessor_uint8();
    extern void ffi_pl_record_accessor_uint16();
    extern void ffi_pl_record_accessor_uint32();
    extern void ffi_pl_record_accessor_uint64();
    extern void ffi_pl_record_accessor_sint8();
    extern void ffi_pl_record_accessor_sint16();
    extern void ffi_pl_record_accessor_sint32();
    extern void ffi_pl_record_accessor_sint64();
    extern void ffi_pl_record_accessor_float();
    extern void ffi_pl_record_accessor_double();
  CODE:
    if(type->platypus_type != FFI_PL_NATIVE)
      croak("type not supported");
  
    Newx(member, 1, ffi_pl_record_member);
    member->offset = offset;
    member->count  = 1;
    
    switch(type->ffi_type->type)
    {
      case FFI_TYPE_UINT8:
        function = ffi_pl_record_accessor_uint8;
        break;
      case FFI_TYPE_SINT8:
        function = ffi_pl_record_accessor_sint8;
        break;
      case FFI_TYPE_UINT16:
        function = ffi_pl_record_accessor_uint16;
        break;
      case FFI_TYPE_SINT16:
        function = ffi_pl_record_accessor_sint16;
        break;
      case FFI_TYPE_UINT32:
        function = ffi_pl_record_accessor_uint32;
        break;
      case FFI_TYPE_SINT32:
        function = ffi_pl_record_accessor_sint32;
        break;
      case FFI_TYPE_UINT64:
        function = ffi_pl_record_accessor_uint64;
        break;
      case FFI_TYPE_SINT64:
        function = ffi_pl_record_accessor_sint64;
        break;
      case FFI_TYPE_FLOAT:
        function = ffi_pl_record_accessor_float;
        break;
      case FFI_TYPE_DOUBLE:
        function = ffi_pl_record_accessor_double;
        break;
      default:
        Safefree(member);
        croak("type not supported");
        break;
    }
    
    if(path_name == NULL)
      path_name = "unknown";
    
    /*
     * this ifdef is needed for Perl 5.8.8 support.
     * once we don't need to support 5.8.8 we can
     * remove this workaround (the ndef'd branch)
     */
#ifdef newXS_flags
    cv = newXSproto(perl_name, function, path_name, "$;$");
#else
    newXSproto(perl_name, function, path_name, "$;$");
    cv = get_cv(perl_name,0);
#endif

    CvXSUBANY(cv).any_ptr = (void*) member;

    
    
