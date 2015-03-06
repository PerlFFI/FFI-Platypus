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

XS(ffi_pl_record_accessor_string_rw)
{
  ffi_pl_record_member *member;
  SV *self;
  SV *arg;
  char *ptr1;
  char **ptr2;
  char *arg_ptr;
  STRLEN len;

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
    arg = ST(1);
    if(SvOK(arg))
    {
      arg_ptr = SvPV(arg, len);
      *ptr2 = realloc(*ptr2, len+1);
      (*ptr2)[len] = 0;
      memcpy(*ptr2, arg_ptr, len);
    }
    else if(*ptr2 != NULL)
    {
      free(*ptr2);
      *ptr2 = NULL;
    }
  }

  if(GIMME_V == G_VOID)
    XSRETURN_EMPTY;

  if(*ptr2 != NULL)
    XSRETURN_PV(*ptr2);
  else
    XSRETURN_EMPTY;
}

XS(ffi_pl_record_accessor_string_fixed)
{
  ffi_pl_record_member *member;
  SV *self;
  SV *arg;
  SV *value;
  char *ptr1;
  char *ptr2;
  char *arg_ptr;
  STRLEN len;

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
  ptr2 = (char*) &ptr1[member->offset];

  if(items > 1)
  {
    arg = ST(1);
    if(SvOK(arg))
    {
      arg_ptr = SvPV(ST(1), len);
      if(len > member->count)
        len = member->count;
      memcpy(ptr2, arg_ptr, len);
    }
    else
    {
      croak("Cannot assign undef to a fixed string field");
    }
  }

  if(GIMME_V == G_VOID)
    XSRETURN_EMPTY;

  value = sv_newmortal();
  sv_setpvn(value, ptr2, member->count);
  ST(0) = value;
  XSRETURN(1);
}
