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
    extern void ffi_pl_record_accessor_opaque();
    extern void ffi_pl_record_accessor_uint8_array();
    extern void ffi_pl_record_accessor_uint16_array();
    extern void ffi_pl_record_accessor_uint32_array();
    extern void ffi_pl_record_accessor_uint64_array();
    extern void ffi_pl_record_accessor_sint8_array();
    extern void ffi_pl_record_accessor_sint16_array();
    extern void ffi_pl_record_accessor_sint32_array();
    extern void ffi_pl_record_accessor_sint64_array();
    extern void ffi_pl_record_accessor_float_array();
    extern void ffi_pl_record_accessor_double_array();
    extern void ffi_pl_record_accessor_opaque_array();
    extern void ffi_pl_record_accessor_string_ro();
    extern void ffi_pl_record_accessor_string_rw();
    extern void ffi_pl_record_accessor_string_fixed();
  CODE:
    Newx(member, 1, ffi_pl_record_member);
    member->offset = offset;
    
    if(type->platypus_type == FFI_PL_NATIVE)
    {
      member->count = 1;
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
        case FFI_TYPE_POINTER:
          function = ffi_pl_record_accessor_opaque;
          break;
        default:
          Safefree(member);
          XSRETURN_PV("type not supported");
          break;
      }
    }
    else if(type->platypus_type == FFI_PL_ARRAY)
    {
      member->count = type->extra[0].array.element_count;
      switch(type->ffi_type->type)
      {
        case FFI_TYPE_UINT8:
          function = ffi_pl_record_accessor_uint8_array;
          break;
        case FFI_TYPE_SINT8:
          function = ffi_pl_record_accessor_sint8_array;
          break;
        case FFI_TYPE_UINT16:
          function = ffi_pl_record_accessor_uint16_array;
          break;
        case FFI_TYPE_SINT16:
          function = ffi_pl_record_accessor_sint16_array;
          break;
        case FFI_TYPE_UINT32:
          function = ffi_pl_record_accessor_uint32_array;
          break;
        case FFI_TYPE_SINT32:
          function = ffi_pl_record_accessor_sint32_array;
          break;
        case FFI_TYPE_UINT64:
          function = ffi_pl_record_accessor_uint64_array;
          break;
        case FFI_TYPE_SINT64:
          function = ffi_pl_record_accessor_sint64_array;
          break;
        case FFI_TYPE_FLOAT:
          function = ffi_pl_record_accessor_float_array;
          break;
        case FFI_TYPE_DOUBLE:
          function = ffi_pl_record_accessor_double_array;
          break;
        case FFI_TYPE_POINTER:
          function = ffi_pl_record_accessor_opaque_array;
          break;
        default:
          Safefree(member);
          XSRETURN_PV("type not supported");
          break;
      }
    }
    else if(type->platypus_type == FFI_PL_STRING)
    {
      switch(type->extra[0].string.platypus_string_type)
      {
        case FFI_PL_STRING_RO:
          member->count = 1;
          function = ffi_pl_record_accessor_string_ro;
          break;
        case FFI_PL_STRING_RW:
          member->count = 1;
          function = ffi_pl_record_accessor_string_rw;
          break;
        case FFI_PL_STRING_FIXED:
          member->count = type->extra[0].string.size;
          function = ffi_pl_record_accessor_string_fixed;
          break;
      }
    }
    else
    {
      Safefree(member);
      XSRETURN_PV("type not supported");
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
    XSRETURN_EMPTY;

