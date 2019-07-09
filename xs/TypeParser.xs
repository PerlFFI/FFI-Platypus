MODULE = FFI::Platypus PACKAGE = FFI::Platypus::TypeParser

BOOT:
{
  HV *bt = get_hv("FFI::Platypus::TypeParser::basic_type", GV_ADD);
  hv_stores(bt, "void",       newSViv(FFI_PL_TYPE_VOID));
  hv_stores(bt, "sint8",      newSViv(FFI_PL_TYPE_SINT8));
  hv_stores(bt, "sint16",     newSViv(FFI_PL_TYPE_SINT16));
  hv_stores(bt, "sint32",     newSViv(FFI_PL_TYPE_SINT32));
  hv_stores(bt, "sint64",     newSViv(FFI_PL_TYPE_SINT64));
  hv_stores(bt, "uint8",      newSViv(FFI_PL_TYPE_UINT8));
  hv_stores(bt, "uint16",     newSViv(FFI_PL_TYPE_UINT16));
  hv_stores(bt, "uint32",     newSViv(FFI_PL_TYPE_UINT32));
  hv_stores(bt, "uint64",     newSViv(FFI_PL_TYPE_UINT64));

  hv_stores(bt, "float",      newSViv(FFI_PL_TYPE_FLOAT));
  hv_stores(bt, "double",     newSViv(FFI_PL_TYPE_DOUBLE));
  hv_stores(bt, "string",     newSViv(FFI_PL_TYPE_STRING));
  hv_stores(bt, "opaque",     newSViv(FFI_PL_TYPE_OPAQUE));
#ifdef FFI_PL_PROBE_LONGDOUBLE
  hv_stores(bt, "longdouble", newSViv(FFI_PL_TYPE_LONG_DOUBLE));
#endif
#ifdef FFI_PL_PROBE_COMPLEX
  hv_stores(bt, "complex_float", newSViv(FFI_PL_TYPE_COMPLEX_FLOAT));
  hv_stores(bt, "complex_double", newSViv(FFI_PL_TYPE_COMPLEX_DOUBLE));
#endif
}

ffi_pl_type *
create_type_basic(self, type_code)
    SV *self
    int type_code
  PREINIT:
    ffi_pl_type *type;
  CODE:
    (void)self;
    type = ffi_pl_type_new(0);
    type->type_code |= type_code;
    RETVAL = type;
  OUTPUT:
    RETVAL

ffi_pl_type *
create_type_record(self, size, record_class, pass_by_value)
    SV *self
    size_t size
    ffi_pl_string record_class
    int pass_by_value
  PREINIT:
    ffi_pl_type *type;
  CODE:
    (void)self;
    type = ffi_pl_type_new(sizeof(ffi_pl_type_extra_record));
    type->type_code |= FFI_PL_BASE_RECORD;
    if(!pass_by_value)
      type->type_code |= FFI_PL_TYPE_OPAQUE;
    type->extra[0].record.size = size;
    if(record_class == NULL)
      type->extra[0].record.stash = NULL;
    else
      type->extra[0].record.stash = gv_stashpv(record_class, GV_ADD);
    RETVAL = type;
  OUTPUT:
    RETVAL

ffi_pl_type *
create_type_string(self, rw)
    SV *self
    int rw
  PREINIT:
    ffi_pl_type *type;
  CODE:
    (void)self;
    type = ffi_pl_type_new(0);
    type->type_code = FFI_PL_TYPE_STRING;
    if(rw)
      type->sub_type = FFI_PL_TYPE_STRING_RW;
    else
      type->sub_type = FFI_PL_TYPE_STRING_RO;
    RETVAL = type;
  OUTPUT:
    RETVAL

ffi_pl_type *
create_type_array(self, type_code, size)
    SV *self
    int type_code
    size_t size
  PREINIT:
    ffi_pl_type *type;
  CODE:
    (void)self;
    type = ffi_pl_type_new(sizeof(ffi_pl_type_extra_array));
    type->type_code |= FFI_PL_SHAPE_ARRAY | type_code;
    type->extra[0].array.element_count = size;
    RETVAL = type;
  OUTPUT:
    RETVAL

ffi_pl_type*
create_type_pointer(self, type_code)
    SV *self
    int type_code
  PREINIT:
    ffi_pl_type *type;
  CODE:
    (void)self;
    type = ffi_pl_type_new(0);
    type->type_code |= FFI_PL_SHAPE_POINTER | type_code;
    RETVAL = type;
  OUTPUT:
    RETVAL

ffi_pl_type *
_create_type_custom(self, type_code, perl_to_native, native_to_perl, perl_to_native_post, argument_count)
    SV *self
    int type_code
    SV *perl_to_native
    SV *native_to_perl
    SV *perl_to_native_post
    int argument_count
  PREINIT:
    ffi_pl_type *type;
    ffi_pl_type_extra_custom_perl *custom;
  CODE:
    (void)self;
    type = ffi_pl_type_new(sizeof(ffi_pl_type_extra_custom_perl));
    type->type_code = FFI_PL_SHAPE_CUSTOM_PERL | type_code;

    custom = &type->extra[0].custom_perl;
    custom->perl_to_native = SvOK(perl_to_native) ? SvREFCNT_inc_simple_NN(perl_to_native) : NULL;
    custom->perl_to_native_post = SvOK(perl_to_native_post) ? SvREFCNT_inc_simple_NN(perl_to_native_post) : NULL;
    custom->native_to_perl = SvOK(native_to_perl) ? SvREFCNT_inc_simple_NN(native_to_perl) : NULL;
    custom->argument_count = argument_count-1;

    RETVAL = type;
  OUTPUT:
    RETVAL


ffi_pl_type *
create_type_closure(self, return_type, ...)
    SV *self
    ffi_pl_type *return_type
  PREINIT:
    ffi_pl_type *type;
    int i;
    SV *arg;
    ffi_type *ffi_return_type;
    ffi_type **ffi_argument_types;
    ffi_status ffi_status;
  CODE:
    (void)self;
    switch(return_type->type_code)
    {
      case FFI_PL_TYPE_VOID:
        ffi_return_type = &ffi_type_void;
        break;
      case FFI_PL_TYPE_SINT8:
        ffi_return_type = &ffi_type_sint8;
        break;
      case FFI_PL_TYPE_SINT16:
        ffi_return_type = &ffi_type_sint16;
        break;
      case FFI_PL_TYPE_SINT32:
        ffi_return_type = &ffi_type_sint32;
        break;
      case FFI_PL_TYPE_SINT64:
        ffi_return_type = &ffi_type_sint64;
        break;
      case FFI_PL_TYPE_UINT8:
        ffi_return_type = &ffi_type_uint8;
        break;
      case FFI_PL_TYPE_UINT16:
        ffi_return_type = &ffi_type_uint16;
        break;
      case FFI_PL_TYPE_UINT32:
        ffi_return_type = &ffi_type_uint32;
        break;
      case FFI_PL_TYPE_UINT64:
        ffi_return_type = &ffi_type_uint64;
        break;
      case FFI_PL_TYPE_FLOAT:
        ffi_return_type = &ffi_type_float;
        break;
      case FFI_PL_TYPE_DOUBLE:
        ffi_return_type = &ffi_type_double;
        break;
      case FFI_PL_TYPE_OPAQUE:
        ffi_return_type = &ffi_type_pointer;
        break;
      default:
        croak("Only native types are supported as closure return types");
        break;
    }

    Newx(ffi_argument_types, items-2, ffi_type*);
    type = ffi_pl_type_new(sizeof(ffi_pl_type_extra_closure) + sizeof(ffi_pl_type)*(items-2));
    type->type_code = FFI_PL_TYPE_CLOSURE;

    type->extra[0].closure.return_type = return_type;
    type->extra[0].closure.flags = 0;

    for(i=0; i<(items-2); i++)
    {
      arg = ST(2+i);
      type->extra[0].closure.argument_types[i] = INT2PTR(ffi_pl_type*, SvIV((SV*)SvRV(arg)));
      switch(type->extra[0].closure.argument_types[i]->type_code)
      {
        case FFI_PL_TYPE_VOID:
          ffi_argument_types[i] = &ffi_type_void;
          break;
        case FFI_PL_TYPE_SINT8:
          ffi_argument_types[i] = &ffi_type_sint8;
          break;
        case FFI_PL_TYPE_SINT16:
          ffi_argument_types[i] = &ffi_type_sint16;
          break;
        case FFI_PL_TYPE_SINT32:
          ffi_argument_types[i] = &ffi_type_sint32;
          break;
        case FFI_PL_TYPE_SINT64:
          ffi_argument_types[i] = &ffi_type_sint64;
          break;
        case FFI_PL_TYPE_UINT8:
          ffi_argument_types[i] = &ffi_type_uint8;
          break;
        case FFI_PL_TYPE_UINT16:
          ffi_argument_types[i] = &ffi_type_uint16;
          break;
        case FFI_PL_TYPE_UINT32:
          ffi_argument_types[i] = &ffi_type_uint32;
          break;
        case FFI_PL_TYPE_UINT64:
          ffi_argument_types[i] = &ffi_type_uint64;
          break;
        case FFI_PL_TYPE_FLOAT:
          ffi_argument_types[i] = &ffi_type_float;
          break;
        case FFI_PL_TYPE_DOUBLE:
          ffi_argument_types[i] = &ffi_type_double;
          break;
        case FFI_PL_TYPE_OPAQUE:
        case FFI_PL_TYPE_STRING:
        case FFI_PL_TYPE_RECORD:
          ffi_argument_types[i] = &ffi_type_pointer;
          break;
        default:
          Safefree(ffi_argument_types);
          croak("Only native types and strings are supported as closure argument types");
          break;
      }
    }

    ffi_status = ffi_prep_cif(
      &type->extra[0].closure.ffi_cif,
      FFI_DEFAULT_ABI,
      items-2,
      ffi_return_type,
      ffi_argument_types
    );

    if(ffi_status != FFI_OK)
    {
      Safefree(type);
      Safefree(ffi_argument_types);
      if(ffi_status == FFI_BAD_TYPEDEF)
        croak("bad typedef");
      else if(ffi_status == FFI_BAD_ABI)
        croak("bad abi");
      else
        croak("unknown error with ffi_prep_cif");
    }

    if( items-2 == 0 )
    {
      type->extra[0].closure.flags |= G_NOARGS;
    }

    if(type->extra[0].closure.return_type->type_code == FFI_PL_TYPE_VOID)
    {
      type->extra[0].closure.flags |= G_DISCARD | G_VOID;
    }
    else
    {
      type->extra[0].closure.flags |= G_SCALAR;
    }

    RETVAL = type;

  OUTPUT:
    RETVAL


