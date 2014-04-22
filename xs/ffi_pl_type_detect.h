#ifndef FFI_PL_TYPE_DETECT_H
#define FFI_PL_TYPE_DETECT_H

#include <stdio.h>

#define signed(type)  (((type)-1) < 0) ? 's' : 'u'
#define numbits(type) (sizeof(type)*8)
#define print(type) printf("|%s|%cint%d|\n", #type, signed(type), (int) numbits(type))

#endif
