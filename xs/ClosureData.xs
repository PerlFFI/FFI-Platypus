MODULE = FFI::Platypus PACKAGE = FFI::Platypus::ClosureData

void
DESTROY(self)
    ffi_pl_closure *self
  CODE:
    SvREFCNT_dec(self->coderef);
    ffi_closure_free(self->ffi_closure);
    Safefree(self);
