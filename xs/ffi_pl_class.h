#ifndef FFI_PL_CLASSES_H
#define FFI_PL_CLASSES_H

typedef const char *ffi_pl_string;
typedef enum { FFI_PL_LANGUAGE_FFI, FFI_PL_LANGUAGE_C } ffi_pl_language;
typedef enum { FFI_PL_REF_NONE, FFI_PL_REF_POINTER } ffi_pl_ref_type;;

typedef struct _ffi_pl_type {
  ffi_pl_language  language;
  const char      *name;
  ffi_type        *ffi_type;
  int              refcount;
  ffi_pl_ref_type  reftype;
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
  ffi_pl_system_library_handle *handle;
  int refcount;
} ffi_pl_lib;

typedef struct _ffi_pl_sub {
  const char       *perl_name;
  const char       *lib_name;
  ffi_pl_signature *signature;
  ffi_pl_lib       *lib;
  CV               *cv;
  void             *function;
  void             *mswin32_real_library_handle;
} ffi_pl_sub;

typedef struct _ffi_pl_closure {
  SV               *coderef;
  I32               flags;
  ffi_closure      *ffi_closure;
  ffi_pl_signature *signature;
  const char       *most_recent_return_value;
  void             *function_pointer;
} ffi_pl_closure;

ffi_pl_type *ffi_pl_type_inc(ffi_pl_type *type);
void ffi_pl_type_dec(ffi_pl_type *type);
ffi_pl_signature *ffi_pl_signature_inc(ffi_pl_signature *signature);
void ffi_pl_signature_dec(ffi_pl_signature *signature);
ffi_pl_lib *ffi_pl_lib_inc(ffi_pl_lib *lib);
int ffi_pl_lib_dec(ffi_pl_lib *lib);
void ffi_pl_closure_call(ffi_cif *cif, void *result, void **arguments, void *user);

#endif
