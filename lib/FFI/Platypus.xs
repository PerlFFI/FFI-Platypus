#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include <ffi.h>
#include <ffi_pl.h>

#if defined(_WIN32) || defined (__CYGWIN__)
# error "todo"
#else
#include <dlfcn.h>
#endif

typedef const char *ffi_pl_string;
typedef enum { FFI_PL_LANGUAGE_NONE, FFI_PL_LANGUAGE_C } ffi_pl_language;

typedef struct _ffi_pl_type {
  ffi_pl_language  language;
  const char      *name;
  ffi_type        *ffi_type;
  int              refcount;
} ffi_pl_type;

typedef struct _ffi_pl_signature {
  ffi_pl_type  *return_type;
  int           argument_count;
  ffi_pl_type **argument_types;
  ffi_cif       ffi_cif;
  ffi_type    **ffi_type;
  int           refcount;
} ffi_pl_signature;

typedef struct _ffi_pl_lib {
  const char *path_name;
#if defined(_WIN32) || defined (__CYGWIN__)
# error "todo"
#else
  void *handle;
#endif
  int refcount;
} ffi_pl_lib;

typedef struct _ffi_pl_sub {
  const char       *perl_name;
  const char       *lib_name;
  ffi_pl_signature *signature;
  ffi_pl_lib       *lib;
  CV               *cv;
  void             *function;
} ffi_pl_sub;

static ffi_pl_type *ffi_pl_type_inc(ffi_pl_type *type)
{
  type->refcount++;
  return type;
}

static void ffi_pl_type_dec(ffi_pl_type *type)
{
  type->refcount--;
  if(type->refcount)
    return;
  Safefree(type->name);
  Safefree(type);
}

static ffi_pl_signature *ffi_pl_signature_inc(ffi_pl_signature *signature)
{
  int i;
  
  ffi_pl_type_inc(signature->return_type);
  for(i=0; i<signature->argument_count; i++)
    ffi_pl_type_inc(signature->argument_types[i]);

  signature->refcount++;
  return signature;
}

static void ffi_pl_signature_dec(ffi_pl_signature *signature)
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

static ffi_pl_lib *ffi_pl_lib_inc(ffi_pl_lib *lib)
{
  lib->refcount++;
  return lib;
}

static int ffi_pl_lib_dec(ffi_pl_lib *lib)
{
  int ret;
  
  lib->refcount--;
  if(lib->refcount)
    return 0;

#if defined(_WIN32) || defined (__CYGWIN__)
# error "TODO"
#else
  ret = dlclose(lib->handle);
#endif
  
  if(lib->path_name != NULL)
    Safefree(lib->path_name);
  Safefree(lib);
  
  return ret;
}

static HV *meta = NULL;

XS(ffi_pl_sub_call)
{
  char key[16];
  ffi_pl_sub *sub;
  SV **sv;
  int i;
  void *argument;
  void **arguments;
  ffi_arg result;
  
  dVAR; dXSARGS;
  
  snprintf(key, sizeof(key), "%p", cv);
  sv = hv_fetch(meta, key, strlen(key), 0);
  if(sv == NULL)
  {
    croak("error finding metadata for %p", cv);
  }
  else
  {
    sub = INT2PTR(ffi_pl_sub*, SvIV(*sv));
    
    if(sub->signature->argument_count != items)
      croak("Wrong number of arguments");
    
    /* TODO: maybe use alloca when available                         */
    /*       problem: detecting when we have a usable implementation */
    Newx(arguments, sub->signature->argument_count, void*);
      
    for(i=0; i < sub->signature->argument_count; i++)
    {
      Newx(arguments[i], sub->signature->argument_types[i]->ffi_type->size, char);
      /* *((int*)arguments[i]) = SvIV(ST(i)); */
      ffi_pl_sv2ffi(arguments[i], ST(i), sub->signature->argument_types[i]);
    }
    
    ffi_call(&sub->signature->ffi_cif, sub->function, &result, arguments);
    
    
    for(i=0; i < sub->signature->argument_count; i++)
    {
      Safefree(arguments[i]);
    }
    Safefree(arguments);
  }

  ST(0) = sv_newmortal();
  sv_setiv(ST(0), (int)result);
  XSRETURN(1);
}

MODULE = FFI::Platypus   PACKAGE = FFI::Platypus

ffi_pl_sub *
_ffi_sub(lib, lib_name, perl_name, signature)
    ffi_pl_lib *lib
    const char *lib_name
    const char *perl_name
    ffi_pl_signature *signature
  PREINIT:
    char key[16];
    CV *new_cv;
    ffi_pl_sub *new_sub;
    void *function;
  CODE:
#if defined(_WIN32) || defined (__CYGWIN__)
# error "todo"
#else
    function = dlsym(lib->handle, lib_name);
#endif

    if(function != NULL)
    {
      Newx(new_sub, 1, ffi_pl_sub);
      /* TODO: hook onto the destruction of the cv to free this stuff */
      new_sub->cv        = newXS(perl_name, ffi_pl_sub_call, lib->path_name != NULL ? lib->path_name : "perl_exe");
      /* TODO: undef for perl_name should be anonymous sub */
      new_sub->perl_name = savepv(perl_name);
      new_sub->lib_name  = savepv(lib_name);
      new_sub->signature = ffi_pl_signature_inc(signature);
      new_sub->lib       = ffi_pl_lib_inc(lib);
      new_sub->function  = function;
    
      if(meta == NULL)
      {
        meta = get_hv("FFI::Platypus::_meta", GV_ADD);
      }
      snprintf(key, sizeof(key), "%p", new_sub->cv);
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-value"
      hv_store(meta, key, strlen(key), newSViv(PTR2IV(new_sub)), 0);
#pragma clang diagnostic pop
      RETVAL = new_sub;
    }
    else
    {
      /* TODO: include lib name in this diagnostic */
      croak("unable to find symbol %s", lib_name);
    }
  OUTPUT:
    RETVAL

ffi_pl_type *
_ffi_type(language, name, code)
    ffi_pl_language language
    const char *name
    const char *code
  PREINIT:
    ffi_pl_type *new_type;
    int bad;
  CODE:
    bad = 0;
    Newx(new_type, 1, ffi_pl_type);
    
    if(language == FFI_PL_LANGUAGE_NONE)
    {
      if(!strcmp(code, "void"))
        new_type->ffi_type = &ffi_type_void;
      else if(!strcmp(code, "uint8"))
        new_type->ffi_type = &ffi_type_uint8;
      else if(!strcmp(code, "sint8"))
        new_type->ffi_type = &ffi_type_sint8;
      else if(!strcmp(code, "uint16"))
        new_type->ffi_type = &ffi_type_uint16;
      else if(!strcmp(code, "sint16"))
        new_type->ffi_type = &ffi_type_sint16;
      else if(!strcmp(code, "uint32"))
        new_type->ffi_type = &ffi_type_uint32;
      else if(!strcmp(code, "sint32"))
        new_type->ffi_type = &ffi_type_sint32;
      else if(!strcmp(code, "uint64"))
        new_type->ffi_type = &ffi_type_uint64;
      else if(!strcmp(code, "sint64"))
        new_type->ffi_type = &ffi_type_sint64;
      else if(!strcmp(code, "float"))
        new_type->ffi_type = &ffi_type_float;
      else if(!strcmp(code, "double"))
        new_type->ffi_type = &ffi_type_double;
      else if(!strcmp(code, "longdouble"))
        new_type->ffi_type = &ffi_type_longdouble;
      else if(!strcmp(code, "pointer"))
        new_type->ffi_type = &ffi_type_pointer;
      else
      {
        croak("No such type: %s", code);
        bad = 1;
      }
    }
    else if(language == FFI_PL_LANGUAGE_C)
    {
      ffi_pl_str2ffi_type(new_type, code);
    }
    else
    {
      croak("Unknown language");
      bad = 1;
    }
    
    if(bad)
    {
      Safefree(new_type);
      RETVAL = NULL;
    }
    else
    {
      new_type->language = language;
      new_type->name     = savepv(name);
      new_type->refcount = 1;
      RETVAL = new_type;
    }
  OUTPUT:
    RETVAL

ffi_pl_signature *
ffi_signature(return_type, ...)
    ffi_pl_type *return_type
  PREINIT:
    ffi_pl_signature *new_signature;
    int i;
    int bad;
    ffi_status status;
    ffi_pl_type *tmp;
  CODE:
    bad = 0;
    for(i = 1; i < items; i++)
    {
      if(!sv_isobject(ST(i)) || !sv_derived_from(ST(i), "FFI::Platypus::Type"))
      {
        croak("ffi_signature takes a list of ffi_type");
        bad = 0;
        break;
      }
      tmp = INT2PTR(ffi_pl_type*, SvIV((SV*)SvRV(ST(i))));
      if(tmp->ffi_type->type == FFI_TYPE_VOID)
      {
        croak("void is an illegal argument type");
        bad = 0;
        break;
      }
    }
    
    if(!bad)
    {
      Newx(new_signature, 1, ffi_pl_signature);
      new_signature->refcount = 1;
      new_signature->return_type = ffi_pl_type_inc(return_type);
      new_signature->argument_count = items - 1;
      Newx(new_signature->argument_types, new_signature->argument_count, ffi_pl_type*);
      Newx(new_signature->ffi_type, new_signature->argument_count, ffi_type*);
      for(i=0; i < new_signature->argument_count; i++)
      {
        new_signature->argument_types[i] = ffi_pl_type_inc(INT2PTR(ffi_pl_type*, SvIV((SV*)SvRV(ST(i+1)))));
        new_signature->ffi_type[i] = new_signature->argument_types[i]->ffi_type;
      }
      status = ffi_prep_cif(
        &new_signature->ffi_cif,              /* ffi_cif* */
        FFI_DEFAULT_ABI,                      /* ffi_abi */
        new_signature->argument_count,        /* unsigned int */
        new_signature->return_type->ffi_type, /* ffi_type *rtype */
        new_signature->ffi_type               /* ffi_type **atype */
      );
      if(status != FFI_OK)
      {
        ffi_pl_signature_dec(new_signature);
        if(status == FFI_BAD_TYPEDEF)
          croak("bad typedef");
        else if(status == FFI_BAD_ABI)
          croak("invalid ABI");
        else
          croak("unknown error with ffi_prep_cif");
      }
      else
      {
        RETVAL = new_signature;
      }
    }
  OUTPUT:
    RETVAL

ffi_pl_lib *
ffi_lib(filename, ...)
    ffi_pl_string filename;
  PREINIT:
#if defined(_WIN32) || defined (__CYGWIN__)
# error "todo"
#else
    int flags;
    void *handle;
#endif
    ffi_pl_lib *new_lib;
  CODE:
#if defined(_WIN32) || defined (__CYGWIN__)
# error "todo"
#else
    flags = RTLD_LAZY; /* TODO: additional arguments can specify flags */
    handle = dlopen(filename, flags);
    if(handle == NULL)
    {
      croak("error in dlopen(%s,%d): %s", filename != NULL ? filename : "undef", flags, dlerror()); 
    }
    else
    {
      Newx(new_lib, 1, ffi_pl_lib);
      new_lib->refcount = 1;
      new_lib->path_name = filename != NULL ? savepv(filename) : NULL;
      new_lib->handle = handle;
      RETVAL = new_lib;
    }
#endif
  OUTPUT:
    RETVAL
    

MODULE = FFI::Platypus   PACKAGE = FFI::Platypus::Type

size_t
size(self)
    ffi_pl_type *self
  CODE:
    RETVAL = self->ffi_type->size;
  OUTPUT:
    RETVAL

ffi_pl_language
language(self)
    ffi_pl_type *self
  CODE:
    RETVAL = self->language;
  OUTPUT:
    RETVAL

const char *
name(self)
    ffi_pl_type *self
  CODE:
    RETVAL = self->name;
  OUTPUT:
    RETVAL

int
_libffi_type(self)
    ffi_pl_type *self
  CODE:
    RETVAL = self->ffi_type->type;
  OUTPUT:
    RETVAL

int
_refcount(self)
    ffi_pl_type *self
  CODE:
    RETVAL = self->refcount;
  OUTPUT:
    RETVAL

void
DESTROY(self)
    ffi_pl_type *self
  CODE:
    ffi_pl_type_dec(self);

MODULE = FFI::Platypus   PACKAGE = FFI::Platypus::Signature

ffi_pl_type *
return_type(self)
    ffi_pl_signature *self
  CODE:
    RETVAL = ffi_pl_type_inc(self->return_type);
  OUTPUT:
    RETVAL

int
argument_count(self)
    ffi_pl_signature *self
  CODE:
    RETVAL = self->argument_count;
  OUTPUT:
    RETVAL

ffi_pl_type *
argument_type(self, index)
    ffi_pl_signature *self
    unsigned int index
  CODE:
    if(index >= self->argument_count)
      croak("no such argument index %d (max is %d)", index, self->argument_count-1);
    else
      RETVAL = ffi_pl_type_inc(self->argument_types[index]);
  OUTPUT:
    RETVAL

int
_refcount(self)
    ffi_pl_signature *self
  CODE:
    RETVAL = self->refcount;
  OUTPUT:
    RETVAL

void
DESTROY(self)
    ffi_pl_signature *self
  CODE:
    ffi_pl_signature_dec(self);

MODULE = FFI::Platypus   PACKAGE = FFI::Platypus::Lib

ffi_pl_string
path_name(self)
    ffi_pl_lib *self
  CODE:
    RETVAL = self->path_name;
  OUTPUT:
    RETVAL

void *
has_symbol(self, name)
    ffi_pl_lib *self
    const char *name
  CODE:
#if defined(_WIN32) || defined (__CYGWIN__)
# error "todo"
#else
    RETVAL = dlsym(self->handle, name);
#endif
  OUTPUT:
    RETVAL

int
_refcount(self)
    ffi_pl_lib *self
  CODE:
    RETVAL = self->refcount;
  OUTPUT:
    RETVAL

void *
_handle(self)
    ffi_pl_lib *self
  CODE:
#if defined(_WIN32) || defined (__CYGWIN__)
# error "todo"
#else
    RETVAL = self->handle;
#endif
  OUTPUT:
    RETVAL

void
DESTROY(self)
    ffi_pl_lib *self
  CODE:
    /* TODO: check return value */
    ffi_pl_lib_dec(self);

MODULE = FFI::Platypus   PACKAGE = FFI::Platypus::Sub
