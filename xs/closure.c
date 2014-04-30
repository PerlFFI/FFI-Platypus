#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include <ffi.h>
#include <ffi_pl.h>
#include <ffi_pl_class.h>

void
ffi_pl_closure_call(ffi_cif *cif, void *result, void **arguments, void *user)
{
  dSP;

  ffi_pl_closure *closure = (ffi_pl_closure*) user;
  printf("in closure\n");

  PUSHMARK(SP);
  call_sv(closure->coderef, G_DISCARD|G_NOARGS);

  fflush(stdout);
}

