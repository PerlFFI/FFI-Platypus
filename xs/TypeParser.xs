MODULE = FFI::Platypus PACKAGE = FFI::Platypus::TypeParser

ffi_pl_type *
create_type_record(class, size, record_class, pass_by_value)
    const char *class
    size_t size
    ffi_pl_string record_class
    int pass_by_value
  PREINIT:
    ffi_pl_type *type;
  CODE:
    (void)class;
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
create_type_string(class, rw)
    const char *class
    int rw
  PREINIT:
    ffi_pl_type *type;
  CODE:
    (void)class;
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
create_type_array(class, name, size)
    const char *class
    const char *name
    size_t size
  PREINIT:
    ffi_pl_type *type;
    int type_code;
    dMY_CXT;
  CODE:
    type_code = ffi_pl_name_to_code(name);
    if(type_code == -1)
      croak("unknown ffi/platypus type: %s/array", name);
    probe_for_math_stuff(name);
    type = ffi_pl_type_new(sizeof(ffi_pl_type_extra_array));
    type->type_code |= FFI_PL_SHAPE_ARRAY | type_code;
    type->extra[0].array.element_count = size;
    RETVAL = type;
  OUTPUT:
    RETVAL

ffi_pl_type*
create_type_pointer(class, name)
    const char *class
    const char *name
  PREINIT:
    ffi_pl_type *type;
    int type_code;
    dMY_CXT;
  CODE:
    type_code = ffi_pl_name_to_code(name);
    if(type_code == -1)
      croak("unknown ffi/platypus type: %s/pointer", name);
    probe_for_math_stuff(name);
    type = ffi_pl_type_new(0);
    type->type_code |= FFI_PL_SHAPE_POINTER | type_code;
    RETVAL = type;
  OUTPUT:
    RETVAL

ffi_pl_type *
create_old(class, type, fuzzy_type, array_or_record_or_string_size, type_classname, rw)
    const char *class
    const char *type
    const char *fuzzy_type
    size_t array_or_record_or_string_size
    ffi_pl_string type_classname
    int rw
  PREINIT:
    ffi_pl_type *self;
    dMY_CXT;
  CODE:
    (void)class;
    self = NULL;
    probe_for_math_stuff(type);
    if(strcmp(fuzzy_type, "ffi"))
    {
      croak("unknown ffi/platypus type: %s/%s", type, fuzzy_type);
    }
    self = ffi_pl_type_new(0);
    int type_code = ffi_pl_name_to_code(type);
    if(type_code == -1)
    {
      Safefree(self);
      self = NULL;
      croak("unknown ffi/platypus type: %s/%s", type, fuzzy_type);
    }
    self->type_code |= type_code;
    RETVAL = self;
  OUTPUT:
    RETVAL

ffi_pl_type *
create_type_custom(class, type, perl_to_native, native_to_perl, perl_to_native_post, argument_count)
    const char *class
    const char *type
    SV *perl_to_native
    SV *native_to_perl
    SV *perl_to_native_post
    int argument_count
  PREINIT:
    ffi_pl_type *self;
    ffi_pl_type_extra_custom_perl *custom;
    int type_code;
  CODE:
    (void)class;
    type_code = ffi_pl_name_to_code(type);
    if(type_code == -1)
      croak("unknown ffi/platypus type: %s/custom", type);

    self = ffi_pl_type_new(sizeof(ffi_pl_type_extra_custom_perl));
    self->type_code = FFI_PL_SHAPE_CUSTOM_PERL | type_code;

    custom = &self->extra[0].custom_perl;
    custom->perl_to_native = SvOK(perl_to_native) ? SvREFCNT_inc_simple_NN(perl_to_native) : NULL;
    custom->perl_to_native_post = SvOK(perl_to_native_post) ? SvREFCNT_inc_simple_NN(perl_to_native_post) : NULL;
    custom->native_to_perl = SvOK(native_to_perl) ? SvREFCNT_inc_simple_NN(native_to_perl) : NULL;
    custom->argument_count = argument_count-1;

    RETVAL = self;
  OUTPUT:
    RETVAL


ffi_pl_type *
create_type_closure(class, return_type, ...)
    const char *class;
    ffi_pl_type *return_type
  PREINIT:
    ffi_pl_type *self;
    int i;
    SV *arg;
    ffi_type *ffi_return_type;
    ffi_type **ffi_argument_types;
    ffi_status ffi_status;
  CODE:
    (void)class;
    switch(return_type->type_code)
    {
      case FFI_PL_TYPE_VOID:
      case FFI_PL_TYPE_SINT8:
      case FFI_PL_TYPE_SINT16:
      case FFI_PL_TYPE_SINT32:
      case FFI_PL_TYPE_SINT64:
      case FFI_PL_TYPE_UINT8:
      case FFI_PL_TYPE_UINT16:
      case FFI_PL_TYPE_UINT32:
      case FFI_PL_TYPE_UINT64:
      case FFI_PL_TYPE_FLOAT:
      case FFI_PL_TYPE_DOUBLE:
      case FFI_PL_TYPE_OPAQUE:
        break;
      default:
        croak("Only native types are supported as closure return types");
        break;
    }

    for(i=0; i<(items-2); i++)
    {
      arg = ST(2+i);
      ffi_pl_type *arg_type = INT2PTR(ffi_pl_type*, SvIV((SV*)SvRV(arg)));
      switch(arg_type->type_code)
      {
        case FFI_PL_TYPE_VOID:
        case FFI_PL_TYPE_SINT8:
        case FFI_PL_TYPE_SINT16:
        case FFI_PL_TYPE_SINT32:
        case FFI_PL_TYPE_SINT64:
        case FFI_PL_TYPE_UINT8:
        case FFI_PL_TYPE_UINT16:
        case FFI_PL_TYPE_UINT32:
        case FFI_PL_TYPE_UINT64:
        case FFI_PL_TYPE_FLOAT:
        case FFI_PL_TYPE_DOUBLE:
        case FFI_PL_TYPE_OPAQUE:
        case FFI_PL_TYPE_STRING:
        case FFI_PL_TYPE_RECORD:
          break;
        default:
          croak("Only native types and strings are supported as closure argument types");
          break;
      }
    }

    Newx(ffi_argument_types, items-2, ffi_type*);
    self = ffi_pl_type_new(sizeof(ffi_pl_type_extra_closure) + sizeof(ffi_pl_type)*(items-2));
    self->type_code = FFI_PL_TYPE_CLOSURE;

    self->extra[0].closure.return_type = return_type;
    self->extra[0].closure.flags = 0;

    ffi_return_type = ffi_pl_type_to_libffi_type(return_type);

    for(i=0; i<(items-2); i++)
    {
      arg = ST(2+i);
      self->extra[0].closure.argument_types[i] = INT2PTR(ffi_pl_type*, SvIV((SV*)SvRV(arg)));
      ffi_argument_types[i] = ffi_pl_type_to_libffi_type(self->extra[0].closure.argument_types[i]);
    }

    ffi_status = ffi_prep_cif(
      &self->extra[0].closure.ffi_cif,
      FFI_DEFAULT_ABI,
      items-2,
      ffi_return_type,
      ffi_argument_types
    );

    if(ffi_status != FFI_OK)
    {
      Safefree(self);
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
      self->extra[0].closure.flags |= G_NOARGS;
    }

    if(self->extra[0].closure.return_type->type_code == FFI_PL_TYPE_VOID)
    {
      self->extra[0].closure.flags |= G_DISCARD | G_VOID;
    }
    else
    {
      self->extra[0].closure.flags |= G_SCALAR;
    }

    RETVAL = self;

  OUTPUT:
    RETVAL


