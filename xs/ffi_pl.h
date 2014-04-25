#ifndef FFI_PL_H
#define FFI_PL_H

#include "ffi_pl_config.h"

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

#endif
