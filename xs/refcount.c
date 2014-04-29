#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include <ffi.h>
#include <ffi_pl.h>
#include <ffi_pl_class.h>

ffi_pl_type *ffi_pl_type_inc(ffi_pl_type *type)
{
  type->refcount++;
  return type;
}

void ffi_pl_type_dec(ffi_pl_type *type)
{
  type->refcount--;
  if(type->refcount)
    return;
  Safefree(type);
}

ffi_pl_signature *ffi_pl_signature_inc(ffi_pl_signature *signature)
{
  int i;

  ffi_pl_type_inc(signature->return_type);
  for(i=0; i<signature->argument_count; i++)
    ffi_pl_type_inc(signature->argument_types[i]);

  signature->refcount++;
  return signature;
}

void ffi_pl_signature_dec(ffi_pl_signature *signature)
{
  int i;

  ffi_pl_type_dec(signature->return_type);
  for(i=0; i<signature->argument_count; i++)
    ffi_pl_type_dec(signature->argument_types[i]);

  signature->refcount--;
  if(signature->refcount)
    return;
  Safefree(signature->argument_types);
  Safefree(signature->ffi_type);
  Safefree(signature);
}

ffi_pl_lib *ffi_pl_lib_inc(ffi_pl_lib *lib)
{
  lib->refcount++;
  return lib;
}

int ffi_pl_lib_dec(ffi_pl_lib *lib)
{
  int ret;

  lib->refcount--;
  if(lib->refcount)
    return 0;

  dlclose(lib->handle);

  if(lib->path_name != NULL)
    Safefree(lib->path_name);
  Safefree(lib);

  return ret;
}

