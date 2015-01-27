#ifndef FFI_PLATYPUS_GUTS_H
#define FFI_PLATYPUS_GUTS_H
#ifdef __cplusplus
extern "C" {
#endif

void ffi_pl_closure_call(ffi_cif *, void *, void **, void *);
void ffi_pl_closure_add_data(SV *closure, ffi_pl_closure *closure_data);
SV*  ffi_pl_custom_perl(SV*,SV*,int);
void ffi_pl_custom_perl_cb(SV *, SV*, int);
HV *ffi_pl_get_type_meta(ffi_pl_type *);
size_t ffi_pl_sizeof(ffi_pl_type *);

#ifdef __cplusplus
}
#endif
#endif
