MODULE = FFI::Platypus PACKAGE = FFI::Platypus::Internal

void
_init()
  INIT:
    HV *stash;
  CODE:
    stash = gv_stashpv("FFI::Platypus::Internal", TRUE);
    newCONSTSUB(stash, "FFI_PL_SIZE_0",     newSViv(FFI_PL_SIZE_0));
    newCONSTSUB(stash, "FFI_PL_SIZE_8",     newSViv(FFI_PL_SIZE_8));
    newCONSTSUB(stash, "FFI_PL_SIZE_16",    newSViv(FFI_PL_SIZE_16));
    newCONSTSUB(stash, "FFI_PL_SIZE_32",    newSViv(FFI_PL_SIZE_32));
    newCONSTSUB(stash, "FFI_PL_SIZE_64",    newSViv(FFI_PL_SIZE_64));
    newCONSTSUB(stash, "FFI_PL_SIZE_128",   newSViv(FFI_PL_SIZE_128));
    newCONSTSUB(stash, "FFI_PL_SIZE_256",   newSViv(FFI_PL_SIZE_256));
    newCONSTSUB(stash, "FFI_PL_SIZE_512",   newSViv(FFI_PL_SIZE_512));
    newCONSTSUB(stash, "FFI_PL_SIZE_PTR",   newSViv(FFI_PL_SIZE_PTR));
    newCONSTSUB(stash, "FFI_PL_SIZE_MASK",  newSViv(FFI_PL_SIZE_MASK));

    newCONSTSUB(stash, "FFI_PL_BASE_VOID",     newSViv(FFI_PL_BASE_VOID));
    newCONSTSUB(stash, "FFI_PL_BASE_SINT",     newSViv(FFI_PL_BASE_SINT));
    newCONSTSUB(stash, "FFI_PL_BASE_UINT",     newSViv(FFI_PL_BASE_UINT));
    newCONSTSUB(stash, "FFI_PL_BASE_FLOAT",    newSViv(FFI_PL_BASE_FLOAT));
    newCONSTSUB(stash, "FFI_PL_BASE_COMPLEX",  newSViv(FFI_PL_BASE_COMPLEX));
    newCONSTSUB(stash, "FFI_PL_BASE_OPAQUE",   newSViv(FFI_PL_BASE_OPAQUE));
    newCONSTSUB(stash, "FFI_PL_BASE_STRING",   newSViv(FFI_PL_BASE_STRING));
    newCONSTSUB(stash, "FFI_PL_BASE_CLOSURE",  newSViv(FFI_PL_BASE_CLOSURE));
    newCONSTSUB(stash, "FFI_PL_BASE_RECORD",   newSViv(FFI_PL_BASE_RECORD));
    newCONSTSUB(stash, "FFI_PL_BASE_MASK",     newSViv(FFI_PL_BASE_MASK));

    newCONSTSUB(stash, "FFI_PL_SHAPE_SCALAR",        newSViv(FFI_PL_SHAPE_SCALAR));
    newCONSTSUB(stash, "FFI_PL_SHAPE_POINTER",       newSViv(FFI_PL_SHAPE_POINTER));
    newCONSTSUB(stash, "FFI_PL_SHAPE_ARRAY",         newSViv(FFI_PL_SHAPE_ARRAY));
    newCONSTSUB(stash, "FFI_PL_SHAPE_CUSTOM_PERL",   newSViv(FFI_PL_SHAPE_CUSTOM_PERL));
    newCONSTSUB(stash, "FFI_PL_SHAPE_CUSTOM_MASK",   newSViv(FFI_PL_SHAPE_MASK));

    newCONSTSUB(stash, "FFI_PL_TYPE_VOID",             newSViv(FFI_PL_TYPE_VOID));
    newCONSTSUB(stash, "FFI_PL_TYPE_SINT8",            newSViv(FFI_PL_TYPE_SINT8));
    newCONSTSUB(stash, "FFI_PL_TYPE_SINT16",           newSViv(FFI_PL_TYPE_SINT16));
    newCONSTSUB(stash, "FFI_PL_TYPE_SINT32",           newSViv(FFI_PL_TYPE_SINT32));
    newCONSTSUB(stash, "FFI_PL_TYPE_SINT64",           newSViv(FFI_PL_TYPE_SINT64));
    newCONSTSUB(stash, "FFI_PL_TYPE_UINT8",            newSViv(FFI_PL_TYPE_UINT8));
    newCONSTSUB(stash, "FFI_PL_TYPE_UINT16",           newSViv(FFI_PL_TYPE_UINT16));
    newCONSTSUB(stash, "FFI_PL_TYPE_UINT32",           newSViv(FFI_PL_TYPE_UINT32));
    newCONSTSUB(stash, "FFI_PL_TYPE_UINT64",           newSViv(FFI_PL_TYPE_UINT64));
    newCONSTSUB(stash, "FFI_PL_TYPE_FLOAT",            newSViv(FFI_PL_TYPE_FLOAT));
    newCONSTSUB(stash, "FFI_PL_TYPE_DOUBLE",           newSViv(FFI_PL_TYPE_DOUBLE));
    newCONSTSUB(stash, "FFI_PL_TYPE_LONG_DOUBLE",      newSViv(FFI_PL_TYPE_LONG_DOUBLE));
    newCONSTSUB(stash, "FFI_PL_TYPE_COMPLEX_FLOAT",    newSViv(FFI_PL_TYPE_COMPLEX_FLOAT));
    newCONSTSUB(stash, "FFI_PL_TYPE_COMPLEX_DOUBLE",   newSViv(FFI_PL_TYPE_COMPLEX_DOUBLE));
    newCONSTSUB(stash, "FFI_PL_TYPE_OPAQUE",           newSViv(FFI_PL_TYPE_OPAQUE));

    newCONSTSUB(stash, "FFI_PL_TYPE_STRING",           newSViv(FFI_PL_TYPE_STRING));
    newCONSTSUB(stash, "FFI_PL_TYPE_CLOSURE",          newSViv(FFI_PL_TYPE_CLOSURE));
    newCONSTSUB(stash, "FFI_PL_TYPE_RECORD",           newSViv(FFI_PL_TYPE_RECORD));
