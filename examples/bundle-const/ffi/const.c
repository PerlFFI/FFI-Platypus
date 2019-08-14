#include <ffi_platypus_bundle.h>
#include "myheader.h"

void ffi_pl_bundle_constant(const char *package, ffi_platypus_constant_t *c)
{
  c->set_str("MYVERSION_STRING", MYVERSION_STRING);
  c->set_uint("MYVERSION_MAJOR", MYVERSION_MAJOR);
  c->set_uint("MYVERSION_MINOR", MYVERSION_MINOR);
  c->set_uint("MYVERSION_PATCH", MYVERSION_PATCH);
  c->set_sint("MYBAD", MYBAD);
  c->set_sint("MYOK", MYOK);
  c->set_double("MYPI", MYPI);
}
