#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#define MATH_INT64_NATIVE_IF_AVAILABLE
#include "perl_math_int64.h"

#include <ffi.h>
#include <ffi_pl.h>
#include <ffi_pl_class.h>

XS(ffi_pl_sub_call)
{
  ffi_pl_sub *sub;
  int i;
  void **arguments;
  char *scratch1;
  char *scratch2;
  ffi_arg result;    /* TODO: could be a long double, which is larger than ffi_arg */
  
  dVAR; dXSARGS;

  /* uncomment to send a signal 2 to debug
     this call */
  /* ffi_pl_debug_break(); */
  
  sub = (ffi_pl_sub*) CvXSUBANY(cv).any_ptr;

  scratch2 = NULL;
    
  if(sub->signature->argument_count != items)
    croak("Wrong number of arguments");

#ifdef HAS_ALLOCA
  arguments = alloca(sub->signature->argument_count * sizeof(void*));
  /* TODO: sizeof(long double) could be larger than FFI_SIZEOF_ARG */
  scratch1  = alloca(sub->signature->argument_count * FFI_SIZEOF_ARG);
#else    
  Newx(arguments, sub->signature->argument_count, void*);
  Newx(scratch1,  sub->signature->argument_count * FFI_SIZEOF_ARG, char);
#endif
#ifdef FFI_PLATYPUS_DEBUG
  memset(arguments, 0, sub->signature->argument_count * sizeof(void*));
  memset(scratch1,  0, sub->signature->argument_count * FFI_SIZEOF_ARG);
#endif
      
  for(i=0; i < sub->signature->argument_count; i++)
  {
    arguments[i] = &scratch1[i*FFI_SIZEOF_ARG];
    switch(sub->signature->argument_types[i]->reftype)
    {
      case FFI_PL_REF_NONE:
        ffi_pl_sv2ffi(arguments[i], ST(i), sub->signature->argument_types[i]);
        break;
      case FFI_PL_REF_POINTER:
        if(!SvOK(ST(i)))
        {
          *((void**)arguments[i]) = NULL;
        }
        else if(SvROK(ST(i)))
        {
          if(sv_isobject(ST(i)) && sv_derived_from(ST(i), "FFI::Platypus::Closure"))
          {
            ffi_pl_closure *closure = INT2PTR(ffi_pl_closure *, SvIV((SV *) SvRV(ST(i))));
            *((void**)arguments[i]) = closure->function_pointer;
          }
          else
          {
            void *ptr;
            if(sub->signature->argument_types[i]->ffi_type->type == FFI_TYPE_VOID)
            {
#ifndef HAS_ALLOCA
              Safefree(arguments);
              Safefree(scratch1);
              if(scratch2 != NULL)
                Safefree(scratch2);
#endif
              croak("cannot pass reference in as void pointer type");
            }
#ifdef HAS_ALLOCA
            ptr = alloca(FFI_SIZEOF_ARG);
#else
            if(scratch2 == NULL)
            {
              Newx(scratch2, sub->signature->argument_count * FFI_SIZEOF_ARG, char);
#ifdef FFI_PLATYPUS_DEBUG
              memset(scratch2, 0, sub->signature->argument_count * FFI_SIZEOF_ARG);
#endif
            }
            ptr = &scratch2[i*FFI_SIZEOF_ARG];
#endif
            ffi_pl_sv2ffi(ptr, SvRV(ST(i)), sub->signature->argument_types[i]);
            *((void**)arguments[i]) = ptr;
          }
        }
        else
        {
          *((void**)arguments[i]) = INT2PTR(void *, SvIV(ST(i)));
        }
      break;
    }
  }

#ifdef FFI_PLATYPUS_DEBUG
  fprintf(stderr,   "# ffi_call:\n");
  for(i=0; i < sub->signature->argument_count; i++)
  {
    fprintf(stderr, "#   arg %02d = %016lx [%p]\n", i, *((unsigned long int*)((void*)&scratch1[i*FFI_SIZEOF_ARG])), &scratch1[i*FFI_SIZEOF_ARG]);
  }
#endif
    
  ffi_call(&sub->signature->ffi_cif, sub->function_pointer, &result, arguments);
    
#ifdef FFI_PLATYPUS_DEBUG
  fprintf(stderr,   "#   ret =    %016lx [%p]\n", *((unsigned long int*)((void*)&result)), &result);
#endif

  for(i=0; i < sub->signature->argument_count; i++)
  {
    switch(sub->signature->argument_types[i]->reftype)
    {
      case FFI_PL_REF_NONE:
        /* do nothing */
        break;
      case FFI_PL_REF_POINTER:
        if(SvROK(ST(i)))
        {
          SV *value = SvRV(ST(i));
          if(!SvREADONLY(value))
          {
            void *ptr = *((void**)arguments[i]);
            ffi_pl_ffi2sv(value, ptr, sub->signature->argument_types[i]);
          }
        }
        break;
    }
  }
    
#ifndef HAS_ALLOCA
  Safefree(arguments);
  Safefree(scratch1);
  if(scratch2 != NULL)
    Safefree(scratch2);
#endif

  if(sub->signature->return_type->ffi_type->type == FFI_TYPE_VOID
  && sub->signature->return_type->reftype == FFI_PL_REF_NONE)
  {
    XSRETURN_EMPTY;
  }
  else
  {
    switch(sub->signature->return_type->reftype)
    {
      case FFI_PL_REF_NONE:
        ST(0) = sv_newmortal();
        ffi_pl_ffi2sv(ST(0), (&result), sub->signature->return_type);
        XSRETURN(1);
        break;
      case FFI_PL_REF_POINTER:
        {
          void *ptr = ((void*)result);
          if(ptr == NULL)
            ST(0) = &PL_sv_undef;
          else if(sub->signature->return_type->ffi_type->type == FFI_TYPE_VOID)
            ST(0) = sv_2mortal(newSViv(PTR2IV(ptr)));
          else
          {
            void *tmp = sv_newmortal();
            ffi_pl_ffi2sv(tmp, ((void*)result), sub->signature->return_type);
            ST(0) = newRV_inc(tmp);
            XSRETURN(1);
          }
        }
        break;
    }
  }
}

MODULE = FFI::Platypus   PACKAGE = FFI::Platypus

BOOT:
     PERL_MATH_INT64_LOAD_OR_CROAK;

ffi_pl_sub *
_ffi_meta(sv)
    SV *sv
  CODE:
    /* TODO: check that this really is an XSUB,
       or even better that it really is a ffi_sub */
    RETVAL = CvXSUBANY((CV*)SvRV(sv)).any_ptr;
  OUTPUT:
    RETVAL

ffi_pl_sub *
_ffi_sub(lib, lib_name, perl_name, signature)
    ffi_pl_lib *lib
    const char *lib_name
    const char *perl_name
    ffi_pl_signature *signature
  PREINIT:
    CV *new_cv;
    ffi_pl_sub *new_sub;
    void *function_pointer;
    const char *path_name;
  CODE:
    function_pointer = dlsym(lib->handle, lib_name);

    if(function_pointer != NULL)
    {
      Newx(new_sub, 1, ffi_pl_sub);

      if(dlsym_win32_meta(&path_name, &new_sub->mswin32_real_library_handle))
      {
        /* nothing */
      }
      else
      {
        /* TODO: "perl_exe" should be $ARGV[0] */
        path_name = lib->path_name != NULL ? lib->path_name : "perl_exe";
        new_sub->mswin32_real_library_handle = NULL;
      }
    
      /* TODO: hook onto the destruction of the cv to free this stuff */
      new_sub->cv                = newXS(perl_name, ffi_pl_sub_call, path_name);
      /* TODO: undef for perl_name should be anonymous sub */
      new_sub->perl_name         = savepv(perl_name);
      new_sub->lib_name          = savepv(lib_name);
      new_sub->signature         = ffi_pl_signature_inc(signature);
      new_sub->lib               = ffi_pl_lib_inc(lib);
      new_sub->function_pointer  = function_pointer;

      CvXSUBANY(new_sub->cv).any_ptr      = new_sub;    
      
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
_ffi_type(language, name)
    ffi_pl_language language
    const char *name
  PREINIT:
    ffi_pl_type *new_type;
    int bad;
  CODE:
    bad = 0;
    Newx(new_type, 1, ffi_pl_type);
    new_type->reftype = FFI_PL_REF_NONE;
    if(name[0]=='*')
    {
      /* 
        TODO: the name method should return
              with the pointer prefix (?)
      */
      name++;
      new_type->reftype = FFI_PL_REF_POINTER;
    }
    
    if(language == FFI_PL_LANGUAGE_FFI)
    {
      ffi_pl_str_type2ffi_type(new_type, name);
    }
    else if(language == FFI_PL_LANGUAGE_C)
    {
      ffi_pl_str_c_type2ffi_type(new_type, name);
    }
    else
    {
      Safefree(new_type);
      croak("Unknown language");
    }
    
    new_type->language = language;
    new_type->refcount = 1;
    RETVAL = new_type;
  OUTPUT:
    RETVAL

ffi_pl_signature *
ffi_signature(return_type, ...)
    ffi_pl_type *return_type
  PREINIT:
    ffi_pl_signature *new_signature;
    int i;
    ffi_status status;
    ffi_pl_type *tmp;
    ffi_type *libffi_return_type;
  CODE:
    for(i = 1; i < items; i++)
    {
      if(!sv_isobject(ST(i)) || !sv_derived_from(ST(i), "FFI::Platypus::Type"))
        croak("ffi_signature takes a list of ffi_type");
      tmp = INT2PTR(ffi_pl_type*, SvIV((SV*)SvRV(ST(i))));
      if(tmp->ffi_type->type == FFI_TYPE_VOID && tmp->reftype != FFI_PL_REF_POINTER)
        croak("void is an illegal argument type");
    }
    
    Newx(new_signature, 1, ffi_pl_signature);
    new_signature->refcount = 1;
    new_signature->return_type = ffi_pl_type_inc(return_type);
    new_signature->argument_count = items - 1;
    Newx(new_signature->argument_types, new_signature->argument_count, ffi_pl_type*);
    Newx(new_signature->ffi_type, new_signature->argument_count, ffi_type*);
    for(i=0; i < new_signature->argument_count; i++)
    {
      new_signature->argument_types[i] = ffi_pl_type_inc(INT2PTR(ffi_pl_type*, SvIV((SV*)SvRV(ST(i+1)))));
      switch(new_signature->argument_types[i]->reftype)
      {
        case FFI_PL_REF_NONE:
          new_signature->ffi_type[i] = new_signature->argument_types[i]->ffi_type;
          break;
        case FFI_PL_REF_POINTER:
          new_signature->ffi_type[i] = &ffi_type_pointer;
          break;
      }
    }

    switch(new_signature->return_type->reftype)
    {
      case FFI_PL_REF_NONE:
        libffi_return_type = new_signature->return_type->ffi_type;
        break;
      case FFI_PL_REF_POINTER:
        libffi_return_type = &ffi_type_pointer;
        break;
    }

    status = ffi_prep_cif(
      &new_signature->ffi_cif,              /* ffi_cif* */
      FFI_DEFAULT_ABI,                      /* ffi_abi */
      new_signature->argument_count,        /* unsigned int */
      libffi_return_type,                   /* ffi_type *rtype */
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

    RETVAL = new_signature;
  OUTPUT:
    RETVAL

ffi_pl_lib *
ffi_lib(filename, ...)
    ffi_pl_string filename;
  PREINIT:
    int flags;
    void *handle;
    ffi_pl_lib *new_lib;
  CODE:
#if defined(_WIN32) || defined (__CYGWIN__)
    flags = 0;
#else
    flags = RTLD_LAZY; /* TODO: additional arguments can specify flags */
#endif
    handle = dlopen(filename, flags);
    if(handle == NULL)
      croak("error in dlopen(%s,%d): %s", filename != NULL ? filename : "undef", flags, dlerror()); 

    Newx(new_lib, 1, ffi_pl_lib);
    new_lib->refcount = 1;
    new_lib->path_name = filename != NULL ? savepv(filename) : NULL;
    new_lib->handle = handle;
    RETVAL = new_lib;
  OUTPUT:
    RETVAL

ffi_pl_closure *
ffi_closure(signature, coderef)
    ffi_pl_signature *signature
    SV *coderef
  PREINIT:
    ffi_pl_closure *new_closure;
    ffi_closure *closure;
    ffi_status status;
    void *function_pointer;
  CODE:
    closure = ffi_closure_alloc(sizeof(ffi_closure), &function_pointer);
    if(closure == NULL)
      croak("unable to allocate memory for closure");
    
    Newx(new_closure, 1, ffi_pl_closure);
    new_closure->coderef                  = SvREFCNT_inc(coderef);
    new_closure->signature                = ffi_pl_signature_inc(signature);
    new_closure->most_recent_return_value = NULL;
    new_closure->ffi_closure              = closure;
    new_closure->function_pointer         = function_pointer;
    new_closure->flags                    = 0;
    
    if(new_closure->signature->argument_count == 0)
      new_closure->flags |= G_NOARGS;
      
    if(new_closure->signature->return_type->ffi_type->type == FFI_TYPE_VOID
    && new_closure->signature->return_type->reftype == FFI_PL_REF_NONE)
    {
      new_closure->flags |= G_DISCARD | G_VOID;
    }
    else
    {
      new_closure->flags |= G_SCALAR;
    }
    
    status = ffi_prep_closure_loc(closure, &new_closure->signature->ffi_cif, ffi_pl_closure_call, new_closure, new_closure->function_pointer);
    
    if(status != FFI_OK)
    {
      ffi_closure_free(new_closure->ffi_closure);
      SvREFCNT_dec(new_closure->coderef);
      ffi_pl_signature_dec(new_closure->signature);
      Safefree(new_closure);
      croak("unable to create closure");
    }
    
    RETVAL = new_closure;
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
    RETVAL = dlsym(self->handle, name);
    dlsym_win32_meta(NULL,NULL);
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
    dlclose(self->handle);
    RETVAL = self->handle;
  OUTPUT:
    RETVAL

void
DESTROY(self)
    ffi_pl_lib *self
  CODE:
    /* TODO: check return value */
    ffi_pl_lib_dec(self);

MODULE = FFI::Platypus   PACKAGE = FFI::Platypus::Sub

const char *
perl_name(self)
    ffi_pl_sub *self
  CODE:
    RETVAL = self->perl_name;
  OUTPUT:
    RETVAL

const char *
lib_name(self)
    ffi_pl_sub *self
  CODE:
    RETVAL = self->lib_name;
  OUTPUT:
    RETVAL

ffi_pl_signature *
signature(self)
    ffi_pl_sub *self
  CODE:
    RETVAL = ffi_pl_signature_inc(self->signature);
  OUTPUT:
    RETVAL

ffi_pl_lib *
lib(self)
    ffi_pl_sub *self
  CODE:
    RETVAL = ffi_pl_lib_inc(self->lib);
  OUTPUT:
    RETVAL

void *
_function_pointer(self)
    ffi_pl_sub *self
  CODE:
    RETVAL = self->function_pointer;
  OUTPUT:
    RETVAL

void *
_mswin32_real_library_handle(self)
    ffi_pl_sub *self
  CODE:
    RETVAL = self->mswin32_real_library_handle;
  OUTPUT:
    RETVAL

MODULE = FFI::Platypus   PACKAGE = FFI::Platypus::Closure

void
DESTROY(self)
    ffi_pl_closure *self;
  CODE:
    ffi_closure_free(self->ffi_closure);
    ffi_pl_signature_dec(self->signature);
    SvREFCNT_dec(self->coderef);
    if(self->most_recent_return_value == NULL)
      Safefree(self->most_recent_return_value);
    Safefree(self);
    
