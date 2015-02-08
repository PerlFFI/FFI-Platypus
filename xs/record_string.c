#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include "ffi_platypus.h"
#include "ffi_platypus_guts.h"

XS(ffi_pl_record_accessor_string_ro)
{
  ffi_pl_record_member *member;
  SV *self;
  SV *arg;
  char *ptr1;
  char **ptr2;

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
  ptr2 = (char**) &ptr1[member->offset];

  if(items > 1)
  {
    croak("member is read only");
  }

  if(GIMME_V == G_VOID)
    XSRETURN_EMPTY;

  if(*ptr2 != NULL)
    XSRETURN_PV(*ptr2);
  else
    XSRETURN_EMPTY;
}
