#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include "ffi_platypus.h"
#include "ffi_platypus_guts.h"

XS(ffi_pl_record_accessor_uint32)
{
  ffi_pl_record_member *member;
  SV *self;
  char *ptr1;
  uint32_t *ptr2;

  dVAR; dXSARGS;

  if(items == 0)
    croak("This is a method, you must provide at least the object");

  member = (ffi_pl_record_member*) CvXSUBANY(cv).any_ptr;

  self = ST(0);
  if(SvROK(self))
    self = SvRV(self);

  if(!SvOK(self))
    croak("Null record error");

  ptr1 = (char*) SvPV_nolen(self);
  ptr2 = (uint32_t*) &ptr1[member->offset];

  if(items > 1)
    *ptr2 = (uint32_t) SvUV(ST(1));

  XSRETURN_UV(*ptr2);
}
