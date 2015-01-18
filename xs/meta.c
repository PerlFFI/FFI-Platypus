#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include "ffi_platypus.h"

void *
ffi_pl_get_type_meta(ffi_pl_type *self)
{
  HV *meta;
  const char *string;

  meta = newHV();

  if(self->platypus_type == FFI_PL_NATIVE)
  {
    hv_store(meta, "size",          4, newSViv(self->ffi_type->size), 0);
    hv_store(meta, "element_size", 12, newSViv(self->ffi_type->size), 0);
    hv_store(meta, "type",          4, newSVpv("scalar",0),0);
  }
  else if(self->platypus_type == FFI_PL_STRING)
  {
    hv_store(meta, "size",          4, newSViv(sizeof(void*)), 0);
    hv_store(meta, "element_size", 12, newSViv(sizeof(void*)), 0);
    hv_store(meta, "type",          4, newSVpv("string",0),0);
  }
  else if(self->platypus_type == FFI_PL_POINTER)
  {
    hv_store(meta, "size",          4, newSViv(sizeof(void*)), 0);
    hv_store(meta, "element_size", 12, newSViv(self->ffi_type->size), 0);
    hv_store(meta, "type",          4, newSVpv("opaque_pointer",0),0);
  }
  else if(self->platypus_type == FFI_PL_ARRAY)
  {
    hv_store(meta, "size",           4, newSViv(self->ffi_type->size * self->extra[0].array.element_count), 0);
    hv_store(meta, "element_size",  12, newSViv(self->ffi_type->size), 0);
    hv_store(meta, "type",           4, newSVpv("array",0),0);
    hv_store(meta, "element_count", 13, newSViv(self->extra[0].array.element_count), 0);
  }
  else if(self->platypus_type == FFI_PL_CLOSURE)
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

    hv_store(meta, "size",          4, newSViv(sizeof(void*)), 0);
    hv_store(meta, "element_size", 12, newSViv(sizeof(void*)), 0);
    hv_store(meta, "type",          4, newSVpv("closure",0),0);
  }
  else if(self->platypus_type == FFI_PL_CUSTOM_PERL)
  {
    hv_store(meta, "type",          4, newSVpv("custom_perl",0),0);

    if(self->extra[0].custom_perl.perl_to_native != NULL)
      hv_store(meta, "custom_perl_to_native", 18, newRV_inc((SV*)self->extra[0].custom_perl.perl_to_native), 0);

    if(self->extra[0].custom_perl.perl_to_native_post != NULL)
      hv_store(meta, "custom_perl_to_native_post", 23, newRV_inc((SV*)self->extra[0].custom_perl.perl_to_native_post), 0);

    if(self->extra[0].custom_perl.native_to_perl != NULL)
      hv_store(meta, "custom_native_to_perl", 18, newRV_inc((SV*)self->extra[0].custom_perl.native_to_perl), 0);
  }

  switch(self->ffi_type->type)
  {
    case FFI_TYPE_VOID:
      hv_store(meta, "element_type", 12, newSVpv("void",0),0);
      break;
    case FFI_TYPE_FLOAT:
    case FFI_TYPE_DOUBLE:
    case FFI_TYPE_LONGDOUBLE:
      hv_store(meta, "element_type", 12, newSVpv("float",0),0);
      break;
    case FFI_TYPE_UINT8:
    case FFI_TYPE_UINT16:
    case FFI_TYPE_UINT32:
    case FFI_TYPE_UINT64:
      hv_store(meta, "element_type", 12, newSVpv("int",0),0);
      hv_store(meta, "sign",          4, newSViv(0),0);
      break;
    case FFI_TYPE_SINT8:
    case FFI_TYPE_SINT16:
    case FFI_TYPE_SINT32:
    case FFI_TYPE_SINT64:
      hv_store(meta, "element_type", 12, newSVpv("int",0),0);
      hv_store(meta, "sign",          4, newSViv(1),0);
      break;
    case FFI_TYPE_POINTER:
      hv_store(meta, "element_type", 12, newSVpv("opaque",0),0);
      break;
  }
  switch(self->ffi_type->type)
  {
    case FFI_TYPE_VOID:
      string = "void";
      break;
    case FFI_TYPE_FLOAT:
      string = "float";
      break;
    case FFI_TYPE_DOUBLE:
      string = "double";
      break;
    case FFI_TYPE_LONGDOUBLE:
      string = "longdouble";
      break;
    case FFI_TYPE_UINT8:
      string = "uint8";
      break;
    case FFI_TYPE_SINT8:
      string = "sint8";
      break;
    case FFI_TYPE_UINT16:
      string = "uint16";
      break;
    case FFI_TYPE_SINT16:
      string = "sint16";
      break;
    case FFI_TYPE_UINT32:
      string = "uint32";
      break;
    case FFI_TYPE_SINT32:
      string = "sint32";
      break;
    case FFI_TYPE_UINT64:
      string = "uint64";
      break;
    case FFI_TYPE_SINT64:
      string = "sint64";
      break;
    case FFI_TYPE_POINTER:
      string = "pointer";
      break;
    default:
      string = NULL;
      break;
  }
  hv_store(meta, "ffi_type", 8, newSVpv(string,0),0);

  return meta;
}
