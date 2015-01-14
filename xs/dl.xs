MODULE = FFI::Platypus PACKAGE = FFI::Platypus::dl

void *
dlopen(filename);
    ffi_pl_string filename
  CODE:
    RETVAL = dlopen(filename, RTLD_LAZY);
  OUTPUT:
    RETVAL

const char *
dlerror();

void *
dlsym(handle, symbol);
    void *handle
    const char *symbol

int
dlclose(handle);
    void *handle

