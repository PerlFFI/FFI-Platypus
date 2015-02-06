/* DO NOT MODIFY THIS FILE it is generated from these files: 
 * inc/template/accessor.tt
 * inc/template/accessor_wrapper.tt
 * inc/run/generate_record_accessor.pl
 */
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include "ffi_platypus.h"
#include "ffi_platypus_guts.h"


XS(ffi_pl_record_accessor_uint8)
{
  ffi_pl_record_member *member;
  SV *self;
  char *ptr1;
  uint8_t *ptr2;

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
  ptr2 = (uint8_t*) &ptr1[member->offset];

  if(items > 1)
    *ptr2 = (uint8_t) SvUV(ST(1));

  if(GIMME_V == G_VOID)
    XSRETURN_EMPTY;

  XSRETURN_UV(*ptr2);
}

XS(ffi_pl_record_accessor_sint8)
{
  ffi_pl_record_member *member;
  SV *self;
  char *ptr1;
  int8_t *ptr2;

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
  ptr2 = (int8_t*) &ptr1[member->offset];

  if(items > 1)
    *ptr2 = (int8_t) SvIV(ST(1));

  if(GIMME_V == G_VOID)
    XSRETURN_EMPTY;

  XSRETURN_IV(*ptr2);
}

XS(ffi_pl_record_accessor_uint16)
{
  ffi_pl_record_member *member;
  SV *self;
  char *ptr1;
  uint16_t *ptr2;

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
  ptr2 = (uint16_t*) &ptr1[member->offset];

  if(items > 1)
    *ptr2 = (uint16_t) SvUV(ST(1));

  if(GIMME_V == G_VOID)
    XSRETURN_EMPTY;

  XSRETURN_UV(*ptr2);
}

XS(ffi_pl_record_accessor_sint16)
{
  ffi_pl_record_member *member;
  SV *self;
  char *ptr1;
  int16_t *ptr2;

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
  ptr2 = (int16_t*) &ptr1[member->offset];

  if(items > 1)
    *ptr2 = (int16_t) SvIV(ST(1));

  if(GIMME_V == G_VOID)
    XSRETURN_EMPTY;

  XSRETURN_IV(*ptr2);
}

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

  if(GIMME_V == G_VOID)
    XSRETURN_EMPTY;

  XSRETURN_UV(*ptr2);
}

XS(ffi_pl_record_accessor_sint32)
{
  ffi_pl_record_member *member;
  SV *self;
  char *ptr1;
  int32_t *ptr2;

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
  ptr2 = (int32_t*) &ptr1[member->offset];

  if(items > 1)
    *ptr2 = (int32_t) SvIV(ST(1));

  if(GIMME_V == G_VOID)
    XSRETURN_EMPTY;

  XSRETURN_IV(*ptr2);
}

XS(ffi_pl_record_accessor_uint64)
{
  ffi_pl_record_member *member;
  SV *self;
  char *ptr1;
  uint64_t *ptr2;

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
  ptr2 = (uint64_t*) &ptr1[member->offset];

  if(items > 1)
    *ptr2 = (uint64_t) SvUV(ST(1));

  if(GIMME_V == G_VOID)
    XSRETURN_EMPTY;

  XSRETURN_UV(*ptr2);
}

XS(ffi_pl_record_accessor_sint64)
{
  ffi_pl_record_member *member;
  SV *self;
  char *ptr1;
  int64_t *ptr2;

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
  ptr2 = (int64_t*) &ptr1[member->offset];

  if(items > 1)
    *ptr2 = (int64_t) SvIV(ST(1));

  if(GIMME_V == G_VOID)
    XSRETURN_EMPTY;

  XSRETURN_IV(*ptr2);
}

XS(ffi_pl_record_accessor_float)
{
  ffi_pl_record_member *member;
  SV *self;
  char *ptr1;
  float *ptr2;

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
  ptr2 = (float*) &ptr1[member->offset];

  if(items > 1)
    *ptr2 = (float) SvNV(ST(1));

  if(GIMME_V == G_VOID)
    XSRETURN_EMPTY;

  XSRETURN_NV(*ptr2);
}

XS(ffi_pl_record_accessor_double)
{
  ffi_pl_record_member *member;
  SV *self;
  char *ptr1;
  double *ptr2;

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
  ptr2 = (double*) &ptr1[member->offset];

  if(items > 1)
    *ptr2 = (double) SvNV(ST(1));

  if(GIMME_V == G_VOID)
    XSRETURN_EMPTY;

  XSRETURN_NV(*ptr2);
}

