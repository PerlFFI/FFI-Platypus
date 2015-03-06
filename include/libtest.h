#ifndef LIBTEST_H
#define LIBTEST_H

#include "ffi_platypus.h"

#ifdef HAVE_STDIO_H
#include <stdio.h>
#endif

#ifdef _MSC_VER
#define EXTERN extern __declspec(dllexport)
#else
#define EXTERN extern
#endif

#endif
