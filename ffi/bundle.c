#include <ffi_platypus_bundle.h>

ffi_pl_bundle_t *
ffi_platypus_bundle_api__new(set_str_t set_str,
                             set_sint_t set_sint,
                             set_uint_t set_uint,
                             set_double_t set_double)
{
  ffi_pl_bundle_t *self = malloc(sizeof(ffi_pl_bundle_t));
  self->set_str    = set_str;
  self->set_sint   = set_sint;
  self->set_uint   = set_uint;
  self->set_double = set_double;
  return self;
}

ffi_pl_bundle_t *
ffi_platypus_bundle_api__DESTROY(ffi_pl_bundle_t *self)
{
  free(self);
}
