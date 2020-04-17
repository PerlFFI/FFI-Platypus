#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"
#include "ffi_platypus.h"

/*
 * - negative shift is undefined, so while it may work somewheree we make an explicit check for the
 *   0 size.
 * - We will eventually migrate fixed strings to be internally of record type, for now we have to
 *   check the platypus type when we have a type_code == FFI_PL_BASE_RECORD
 */
#define unit_size(self)                                                                                \
  ((self->type_code & FFI_PL_BASE_MASK) == FFI_PL_BASE_RECORD                                          \
    ? (self->extra[0].record.size)                                                                     \
    : ((self->type_code & FFI_PL_SIZE_MASK) == FFI_PL_SIZE_0                                           \
      ? 0                                                                                              \
      : 1 << ((self->type_code & FFI_PL_SIZE_MASK)-1)                                                  \
    )                                                                                                  \
  )

size_t
ffi_pl_sizeof_new(ffi_pl_type *self)
{
  switch( self->type_code & FFI_PL_SHAPE_MASK )
  {
    case FFI_PL_SHAPE_SCALAR:
    case FFI_PL_SHAPE_CUSTOM_PERL:
      return unit_size(self);
    case FFI_PL_SHAPE_POINTER:
      return sizeof(void*);
    case FFI_PL_SHAPE_ARRAY:
      return unit_size(self) * self->extra[0].array.element_count;
    default:
      return 0;
  }
}

size_t
ffi_pl_sizeof(ffi_pl_type *self)
{
  if(self->type_code == FFI_PL_TYPE_RECORD || self->type_code == FFI_PL_TYPE_RECORD_VALUE)
  {
    return self->extra[0].record.size;
  }
  else
  {
    return ffi_pl_sizeof_new(self);
  }
}

HV *
ffi_pl_get_type_meta(ffi_pl_type *self)
{
  HV *meta;
  const char *string;

  meta = newHV();

  hv_store(meta, "size",      4, newSViv(ffi_pl_sizeof(self)), 0);
  hv_store(meta, "type_code", 9, newSViv(self->type_code), 0);

  switch(self->type_code & FFI_PL_SHAPE_MASK)
  {
    case FFI_PL_SHAPE_SCALAR:
      {
        switch(self->type_code)
        {

          case FFI_PL_TYPE_STRING:
            hv_store(meta, "element_size",  12, newSViv(sizeof(void*)), 0);
            hv_store(meta, "type",           4, newSVpv("string",0),0);
            switch(self->sub_type)
            {
              case FFI_PL_TYPE_STRING_RO:
                hv_store(meta, "access",        6, newSVpv("ro",0), 0);
                break;
              case FFI_PL_TYPE_STRING_RW:
                hv_store(meta, "access",        6, newSVpv("rw",0), 0);
                break;
            }
            break;

          case FFI_PL_TYPE_CLOSURE:
            {
              AV *signature;
              AV *argument_types;
              HV *subtype;
              int i;
              int number_of_arguments;

              number_of_arguments = self->extra[0].closure.ffi_cif.nargs;

              signature = newAV();
              argument_types = newAV();

              for(i=0; i < number_of_arguments; i++)
              {
                subtype = ffi_pl_get_type_meta(self->extra[0].closure.argument_types[i]);
                av_store(argument_types, i, newRV_noinc((SV*)subtype));
              }
              av_store(signature, 0, newRV_noinc((SV*)argument_types));

              subtype = ffi_pl_get_type_meta(self->extra[0].closure.return_type);
              av_store(signature, 1, newRV_noinc((SV*)subtype));

              hv_store(meta, "signature",     9, newRV_noinc((SV*)signature), 0);

              hv_store(meta, "element_size", 12, newSViv(sizeof(void*)), 0);
              hv_store(meta, "type",          4, newSVpv("closure",0),0);
            }
            break;

          case FFI_PL_TYPE_RECORD:
            hv_store(meta, "type",          4, newSVpv("record",0),0);
            hv_store(meta, "ref",           3, newSViv(self->extra[0].record.class != NULL ? 1 : 0),0);
            if(self->extra[0].record.class != NULL)
              hv_store(meta, "class",         5, newSVpv(self->extra[0].record.class,0), 0);
            break;

          case FFI_PL_TYPE_RECORD_VALUE:
            hv_store(meta, "type",          4, newSVpv("record_value",0),0);
            hv_store(meta, "ref",           3, newSViv(self->extra[0].record.class != NULL ? 1 : 0),0);
            hv_store(meta, "class",         5, newSVpv(self->extra[0].record.class,0), 0);
            break;

          default:
            hv_store(meta, "element_size", 12, newSViv(unit_size(self)), 0);
            hv_store(meta, "type",          4, newSVpv("scalar",0),0);
            break;
        }
      }
      break;

    case FFI_PL_SHAPE_POINTER:
      hv_store(meta, "element_size", 12, newSViv(unit_size(self)), 0);
      hv_store(meta, "type",          4, newSVpv("pointer",0),0);
      break;

    case FFI_PL_SHAPE_ARRAY:
      hv_store(meta, "element_size",  12, newSViv(unit_size(self)), 0);
      hv_store(meta, "type",           4, newSVpv("array",0),0);
      hv_store(meta, "element_count", 13, newSViv(self->extra[0].array.element_count), 0);
      break;

    case FFI_PL_SHAPE_CUSTOM_PERL:
      hv_store(meta, "type",          4, newSVpv("custom_perl",0),0);

      if(self->extra[0].custom_perl.perl_to_native != NULL)
        hv_store(meta, "custom_perl_to_native", 18, newRV_inc((SV*)self->extra[0].custom_perl.perl_to_native), 0);

      if(self->extra[0].custom_perl.perl_to_native_post != NULL)
        hv_store(meta, "custom_perl_to_native_post", 23, newRV_inc((SV*)self->extra[0].custom_perl.perl_to_native_post), 0);

      if(self->extra[0].custom_perl.native_to_perl != NULL)
        hv_store(meta, "custom_native_to_perl", 18, newRV_inc((SV*)self->extra[0].custom_perl.native_to_perl), 0);
      break;
  }

  switch(self->type_code & (FFI_PL_SIZE_MASK | FFI_PL_BASE_MASK))
  {
    case FFI_PL_TYPE_VOID:
      hv_store(meta, "element_type", 12, newSVpv("void",0),0);
      break;
    case FFI_PL_TYPE_FLOAT:
    case FFI_PL_TYPE_DOUBLE:
#ifdef FFI_PL_PROBE_LONGDOUBLE
    case FFI_PL_TYPE_LONG_DOUBLE:
#endif
#ifdef FFI_TARGET_HAS_COMPLEX_TYPE
    case FFI_PL_TYPE_COMPLEX_FLOAT:
    case FFI_PL_TYPE_COMPLEX_DOUBLE:
#endif
      hv_store(meta, "element_type", 12, newSVpv("float",0),0);
      break;
    case FFI_PL_TYPE_UINT8:
    case FFI_PL_TYPE_UINT16:
    case FFI_PL_TYPE_UINT32:
    case FFI_PL_TYPE_UINT64:
      hv_store(meta, "element_type", 12, newSVpv("int",0),0);
      hv_store(meta, "sign",          4, newSViv(0),0);
      break;
    case FFI_PL_TYPE_SINT8:
    case FFI_PL_TYPE_SINT16:
    case FFI_PL_TYPE_SINT32:
    case FFI_PL_TYPE_SINT64:
      hv_store(meta, "element_type", 12, newSVpv("int",0),0);
      hv_store(meta, "sign",          4, newSViv(1),0);
      break;
    case FFI_PL_TYPE_OPAQUE:
      hv_store(meta, "element_type", 12, newSVpv("opaque",0),0);
      break;
  }
  switch(self->type_code & (FFI_PL_SIZE_MASK | FFI_PL_BASE_MASK))
  {
    case FFI_PL_TYPE_VOID:
      string = "void";
      break;
    case FFI_PL_TYPE_FLOAT:
      string = "float";
      break;
    case FFI_PL_TYPE_DOUBLE:
      string = "double";
      break;
#ifdef FFI_PL_PROBE_LONGDOUBLE
    case FFI_PL_TYPE_LONG_DOUBLE:
      string = "longdouble";
      break;
#endif
    case FFI_PL_TYPE_UINT8:
      string = "uint8";
      break;
    case FFI_PL_TYPE_SINT8:
      string = "sint8";
      break;
    case FFI_PL_TYPE_UINT16:
      string = "uint16";
      break;
    case FFI_PL_TYPE_SINT16:
      string = "sint16";
      break;
    case FFI_PL_TYPE_UINT32:
      string = "uint32";
      break;
    case FFI_PL_TYPE_SINT32:
      string = "sint32";
      break;
    case FFI_PL_TYPE_UINT64:
      string = "uint64";
      break;
    case FFI_PL_TYPE_SINT64:
      string = "sint64";
      break;
    case FFI_PL_TYPE_OPAQUE:
    case FFI_PL_TYPE_STRING:
    case FFI_PL_TYPE_CLOSURE:
    case FFI_PL_TYPE_RECORD:
      string = "pointer";
      break;
    case FFI_PL_TYPE_RECORD_VALUE:
      string = "struct";
      break;
#ifdef FFI_TARGET_HAS_COMPLEX_TYPE
    case FFI_PL_TYPE_COMPLEX_FLOAT:
      string = "complex_float";
      break;
    case FFI_PL_TYPE_COMPLEX_DOUBLE:
      string = "complex_double";
      break;
#endif
    default:
      warn("bad type: %04x\n", self->type_code & (FFI_PL_SIZE_MASK | FFI_PL_BASE_MASK));
      string = NULL;
      break;
  }
  hv_store(meta, "ffi_type", 8, newSVpv(string,0),0);

  return meta;
}

ffi_pl_type *ffi_pl_type_new(size_t size)
{
  char *buffer;
  ffi_pl_type *self;

  Newx(buffer, sizeof(ffi_pl_type) + size, char);
  self = (ffi_pl_type*) buffer;
  self->type_code = 0;
  self->sub_type = 0;

  return self;
}
