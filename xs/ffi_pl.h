#ifndef FFI_PL_H
#define FFI_PL_H

#include "ffi_pl_config1.h"
#include "ffi_pl_config2.h"

#ifdef HAS_STDLIB_H
#include <stdlib.h>
#endif
#ifdef HAS_STDINT_H
#include <stdint.h>
#endif
#ifdef HAS_SYS_TYPES_H
#include <sys/types.h>
#endif
#ifdef HAS_SYS_STAT_H
#include <sys/stat.h>
#endif
#ifdef HAS_UNISTD_H
#include <unistd.h>
#endif
#ifdef HAS_ALLOCA_H
#include <alloca.h>
#endif
#ifdef HAS_DLFCN_H
#include <dlfcn.h>
#endif
#ifdef HAS_LIMITS_H
#include <limits.h>
#endif

#ifdef _MSC_VER
typedef __int64 int64_t;
typedef unsigned __int64 uint64_t;

#ifndef INT64_MAX
#define INT64_MAX _I64_MAX
#endif
#ifndef INT64_MIN
#define INT64_MIN _I64_MIN
#endif
#ifndef UINT64_MAX
#define UINT64_MAX _UI64_MAX
#endif
#ifndef UINT32_MAX
#define UINT32_MAX _UI32_MAX
#endif

#endif

#ifdef _MSC_VER
# define EXPORT __declspec(dllexport)
#else
# define EXPORT
#endif


#if defined(_WIN32) || defined(__CYGWIN__)

struct _ffi_pl_system_library_handle;
typedef struct _ffi_pl_system_library_handle ffi_pl_system_library_handle;

ffi_pl_system_library_handle *ffi_pl_windows_dlopen(const char *filename, int flags);
void *ffi_pl_windows_dlsym(ffi_pl_system_library_handle *handle, const char *symbol);
const char * ffi_pl_windows_dlerror(void);
int ffi_pl_windows_dlclose(ffi_pl_system_library_handle *handle);

#define dlopen(_filename, _flags)        ffi_pl_windows_dlopen(_filename, _flags)
#define dlsym(_handle, _symbol)          ffi_pl_windows_dlsym(_handle, _symbol)
#define dlerror()                        ffi_pl_windows_dlerror()
#define dlclose(_handle)                 ffi_pl_windows_dlclose(_handle)

#else

typedef void ffi_pl_system_library_handle;

#endif

int ffi_pl_windows_dlsym_win32_meta(const char **mod_name, void **mod_handle);
#define dlsym_win32_meta(_name, _handle) ffi_pl_windows_dlsym_win32_meta(_name, _handle)

#endif
