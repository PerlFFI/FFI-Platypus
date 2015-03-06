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

XS(ffi_pl_record_accessor_uint8_array)
{
  ffi_pl_record_member *member;
  SV *self;
  SV *arg;
  SV **item;
  AV *av;
  char *ptr1;
  int i;
  uint8_t *ptr2;

  dVAR; dXSARGS;

  if(items == 0)
    croak("This is a method, you must provide at least the object");

  member = (ffi_pl_record_member*) CvXSUBANY(cv).any_ptr;

  self = ST(0);
  if(SvROK(self))
    self = SvRV(self);

  ptr1 = (char*) SvPV_nolen(self);
  ptr2 = (uint8_t*) &ptr1[member->offset];

  if(items > 2)
  {
    i       = SvIV(ST(1));
    if(i >= 0 && i < member->count)
    {
      arg     = ST(2);
      ptr2[i] = SvUV(arg);
    }
    else
    {
      warn("illegal index %d", i);
    }
  }
  else if(items > 1)
  {
    arg = ST(1);
    if(SvROK(arg) && SvTYPE(SvRV(arg)) == SVt_PVAV)
    {
      av = (AV*) SvRV(arg);
      for(i=0; i < member->count; i++)
      {
        item = av_fetch(av, i, 0);
        if(item != NULL && SvOK(*item))
        {
          ptr2[i] = SvUV(*item);
        }
        else
        {
          ptr2[i] = 0;
        }
      }
    }
    else
    {
      i = SvIV(ST(1));
      if(i >= 0 && i < member->count)
      {
        XSRETURN_UV(ptr2[i]);
      }
      else
      {
        warn("illegal index %d", i);
        XSRETURN_EMPTY;
      }
    }
  }

  if(GIMME_V == G_VOID)
    XSRETURN_EMPTY;

  av = newAV();
  av_fill(av, member->count-1);
  for(i=0; i < member->count; i++)
  {
    sv_setuv(*av_fetch(av, i, 1), ptr2[i]);
  }
  ST(0) = newRV_inc((SV*)av);
  XSRETURN(1);
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

XS(ffi_pl_record_accessor_sint8_array)
{
  ffi_pl_record_member *member;
  SV *self;
  SV *arg;
  SV **item;
  AV *av;
  char *ptr1;
  int i;
  int8_t *ptr2;

  dVAR; dXSARGS;

  if(items == 0)
    croak("This is a method, you must provide at least the object");

  member = (ffi_pl_record_member*) CvXSUBANY(cv).any_ptr;

  self = ST(0);
  if(SvROK(self))
    self = SvRV(self);

  ptr1 = (char*) SvPV_nolen(self);
  ptr2 = (int8_t*) &ptr1[member->offset];

  if(items > 2)
  {
    i       = SvIV(ST(1));
    if(i >= 0 && i < member->count)
    {
      arg     = ST(2);
      ptr2[i] = SvIV(arg);
    }
    else
    {
      warn("illegal index %d", i);
    }
  }
  else if(items > 1)
  {
    arg = ST(1);
    if(SvROK(arg) && SvTYPE(SvRV(arg)) == SVt_PVAV)
    {
      av = (AV*) SvRV(arg);
      for(i=0; i < member->count; i++)
      {
        item = av_fetch(av, i, 0);
        if(item != NULL && SvOK(*item))
        {
          ptr2[i] = SvIV(*item);
        }
        else
        {
          ptr2[i] = 0;
        }
      }
    }
    else
    {
      i = SvIV(ST(1));
      if(i >= 0 && i < member->count)
      {
        XSRETURN_IV(ptr2[i]);
      }
      else
      {
        warn("illegal index %d", i);
        XSRETURN_EMPTY;
      }
    }
  }

  if(GIMME_V == G_VOID)
    XSRETURN_EMPTY;

  av = newAV();
  av_fill(av, member->count-1);
  for(i=0; i < member->count; i++)
  {
    sv_setiv(*av_fetch(av, i, 1), ptr2[i]);
  }
  ST(0) = newRV_inc((SV*)av);
  XSRETURN(1);
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

XS(ffi_pl_record_accessor_uint16_array)
{
  ffi_pl_record_member *member;
  SV *self;
  SV *arg;
  SV **item;
  AV *av;
  char *ptr1;
  int i;
  uint16_t *ptr2;

  dVAR; dXSARGS;

  if(items == 0)
    croak("This is a method, you must provide at least the object");

  member = (ffi_pl_record_member*) CvXSUBANY(cv).any_ptr;

  self = ST(0);
  if(SvROK(self))
    self = SvRV(self);

  ptr1 = (char*) SvPV_nolen(self);
  ptr2 = (uint16_t*) &ptr1[member->offset];

  if(items > 2)
  {
    i       = SvIV(ST(1));
    if(i >= 0 && i < member->count)
    {
      arg     = ST(2);
      ptr2[i] = SvUV(arg);
    }
    else
    {
      warn("illegal index %d", i);
    }
  }
  else if(items > 1)
  {
    arg = ST(1);
    if(SvROK(arg) && SvTYPE(SvRV(arg)) == SVt_PVAV)
    {
      av = (AV*) SvRV(arg);
      for(i=0; i < member->count; i++)
      {
        item = av_fetch(av, i, 0);
        if(item != NULL && SvOK(*item))
        {
          ptr2[i] = SvUV(*item);
        }
        else
        {
          ptr2[i] = 0;
        }
      }
    }
    else
    {
      i = SvIV(ST(1));
      if(i >= 0 && i < member->count)
      {
        XSRETURN_UV(ptr2[i]);
      }
      else
      {
        warn("illegal index %d", i);
        XSRETURN_EMPTY;
      }
    }
  }

  if(GIMME_V == G_VOID)
    XSRETURN_EMPTY;

  av = newAV();
  av_fill(av, member->count-1);
  for(i=0; i < member->count; i++)
  {
    sv_setuv(*av_fetch(av, i, 1), ptr2[i]);
  }
  ST(0) = newRV_inc((SV*)av);
  XSRETURN(1);
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

XS(ffi_pl_record_accessor_sint16_array)
{
  ffi_pl_record_member *member;
  SV *self;
  SV *arg;
  SV **item;
  AV *av;
  char *ptr1;
  int i;
  int16_t *ptr2;

  dVAR; dXSARGS;

  if(items == 0)
    croak("This is a method, you must provide at least the object");

  member = (ffi_pl_record_member*) CvXSUBANY(cv).any_ptr;

  self = ST(0);
  if(SvROK(self))
    self = SvRV(self);

  ptr1 = (char*) SvPV_nolen(self);
  ptr2 = (int16_t*) &ptr1[member->offset];

  if(items > 2)
  {
    i       = SvIV(ST(1));
    if(i >= 0 && i < member->count)
    {
      arg     = ST(2);
      ptr2[i] = SvIV(arg);
    }
    else
    {
      warn("illegal index %d", i);
    }
  }
  else if(items > 1)
  {
    arg = ST(1);
    if(SvROK(arg) && SvTYPE(SvRV(arg)) == SVt_PVAV)
    {
      av = (AV*) SvRV(arg);
      for(i=0; i < member->count; i++)
      {
        item = av_fetch(av, i, 0);
        if(item != NULL && SvOK(*item))
        {
          ptr2[i] = SvIV(*item);
        }
        else
        {
          ptr2[i] = 0;
        }
      }
    }
    else
    {
      i = SvIV(ST(1));
      if(i >= 0 && i < member->count)
      {
        XSRETURN_IV(ptr2[i]);
      }
      else
      {
        warn("illegal index %d", i);
        XSRETURN_EMPTY;
      }
    }
  }

  if(GIMME_V == G_VOID)
    XSRETURN_EMPTY;

  av = newAV();
  av_fill(av, member->count-1);
  for(i=0; i < member->count; i++)
  {
    sv_setiv(*av_fetch(av, i, 1), ptr2[i]);
  }
  ST(0) = newRV_inc((SV*)av);
  XSRETURN(1);
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

XS(ffi_pl_record_accessor_uint32_array)
{
  ffi_pl_record_member *member;
  SV *self;
  SV *arg;
  SV **item;
  AV *av;
  char *ptr1;
  int i;
  uint32_t *ptr2;

  dVAR; dXSARGS;

  if(items == 0)
    croak("This is a method, you must provide at least the object");

  member = (ffi_pl_record_member*) CvXSUBANY(cv).any_ptr;

  self = ST(0);
  if(SvROK(self))
    self = SvRV(self);

  ptr1 = (char*) SvPV_nolen(self);
  ptr2 = (uint32_t*) &ptr1[member->offset];

  if(items > 2)
  {
    i       = SvIV(ST(1));
    if(i >= 0 && i < member->count)
    {
      arg     = ST(2);
      ptr2[i] = SvUV(arg);
    }
    else
    {
      warn("illegal index %d", i);
    }
  }
  else if(items > 1)
  {
    arg = ST(1);
    if(SvROK(arg) && SvTYPE(SvRV(arg)) == SVt_PVAV)
    {
      av = (AV*) SvRV(arg);
      for(i=0; i < member->count; i++)
      {
        item = av_fetch(av, i, 0);
        if(item != NULL && SvOK(*item))
        {
          ptr2[i] = SvUV(*item);
        }
        else
        {
          ptr2[i] = 0;
        }
      }
    }
    else
    {
      i = SvIV(ST(1));
      if(i >= 0 && i < member->count)
      {
        XSRETURN_UV(ptr2[i]);
      }
      else
      {
        warn("illegal index %d", i);
        XSRETURN_EMPTY;
      }
    }
  }

  if(GIMME_V == G_VOID)
    XSRETURN_EMPTY;

  av = newAV();
  av_fill(av, member->count-1);
  for(i=0; i < member->count; i++)
  {
    sv_setuv(*av_fetch(av, i, 1), ptr2[i]);
  }
  ST(0) = newRV_inc((SV*)av);
  XSRETURN(1);
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

XS(ffi_pl_record_accessor_sint32_array)
{
  ffi_pl_record_member *member;
  SV *self;
  SV *arg;
  SV **item;
  AV *av;
  char *ptr1;
  int i;
  int32_t *ptr2;

  dVAR; dXSARGS;

  if(items == 0)
    croak("This is a method, you must provide at least the object");

  member = (ffi_pl_record_member*) CvXSUBANY(cv).any_ptr;

  self = ST(0);
  if(SvROK(self))
    self = SvRV(self);

  ptr1 = (char*) SvPV_nolen(self);
  ptr2 = (int32_t*) &ptr1[member->offset];

  if(items > 2)
  {
    i       = SvIV(ST(1));
    if(i >= 0 && i < member->count)
    {
      arg     = ST(2);
      ptr2[i] = SvIV(arg);
    }
    else
    {
      warn("illegal index %d", i);
    }
  }
  else if(items > 1)
  {
    arg = ST(1);
    if(SvROK(arg) && SvTYPE(SvRV(arg)) == SVt_PVAV)
    {
      av = (AV*) SvRV(arg);
      for(i=0; i < member->count; i++)
      {
        item = av_fetch(av, i, 0);
        if(item != NULL && SvOK(*item))
        {
          ptr2[i] = SvIV(*item);
        }
        else
        {
          ptr2[i] = 0;
        }
      }
    }
    else
    {
      i = SvIV(ST(1));
      if(i >= 0 && i < member->count)
      {
        XSRETURN_IV(ptr2[i]);
      }
      else
      {
        warn("illegal index %d", i);
        XSRETURN_EMPTY;
      }
    }
  }

  if(GIMME_V == G_VOID)
    XSRETURN_EMPTY;

  av = newAV();
  av_fill(av, member->count-1);
  for(i=0; i < member->count; i++)
  {
    sv_setiv(*av_fetch(av, i, 1), ptr2[i]);
  }
  ST(0) = newRV_inc((SV*)av);
  XSRETURN(1);
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

XS(ffi_pl_record_accessor_uint64_array)
{
  ffi_pl_record_member *member;
  SV *self;
  SV *arg;
  SV **item;
  AV *av;
  char *ptr1;
  int i;
  uint64_t *ptr2;

  dVAR; dXSARGS;

  if(items == 0)
    croak("This is a method, you must provide at least the object");

  member = (ffi_pl_record_member*) CvXSUBANY(cv).any_ptr;

  self = ST(0);
  if(SvROK(self))
    self = SvRV(self);

  ptr1 = (char*) SvPV_nolen(self);
  ptr2 = (uint64_t*) &ptr1[member->offset];

  if(items > 2)
  {
    i       = SvIV(ST(1));
    if(i >= 0 && i < member->count)
    {
      arg     = ST(2);
      ptr2[i] = SvUV(arg);
    }
    else
    {
      warn("illegal index %d", i);
    }
  }
  else if(items > 1)
  {
    arg = ST(1);
    if(SvROK(arg) && SvTYPE(SvRV(arg)) == SVt_PVAV)
    {
      av = (AV*) SvRV(arg);
      for(i=0; i < member->count; i++)
      {
        item = av_fetch(av, i, 0);
        if(item != NULL && SvOK(*item))
        {
          ptr2[i] = SvUV(*item);
        }
        else
        {
          ptr2[i] = 0;
        }
      }
    }
    else
    {
      i = SvIV(ST(1));
      if(i >= 0 && i < member->count)
      {
        XSRETURN_UV(ptr2[i]);
      }
      else
      {
        warn("illegal index %d", i);
        XSRETURN_EMPTY;
      }
    }
  }

  if(GIMME_V == G_VOID)
    XSRETURN_EMPTY;

  av = newAV();
  av_fill(av, member->count-1);
  for(i=0; i < member->count; i++)
  {
    sv_setuv(*av_fetch(av, i, 1), ptr2[i]);
  }
  ST(0) = newRV_inc((SV*)av);
  XSRETURN(1);
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

XS(ffi_pl_record_accessor_sint64_array)
{
  ffi_pl_record_member *member;
  SV *self;
  SV *arg;
  SV **item;
  AV *av;
  char *ptr1;
  int i;
  int64_t *ptr2;

  dVAR; dXSARGS;

  if(items == 0)
    croak("This is a method, you must provide at least the object");

  member = (ffi_pl_record_member*) CvXSUBANY(cv).any_ptr;

  self = ST(0);
  if(SvROK(self))
    self = SvRV(self);

  ptr1 = (char*) SvPV_nolen(self);
  ptr2 = (int64_t*) &ptr1[member->offset];

  if(items > 2)
  {
    i       = SvIV(ST(1));
    if(i >= 0 && i < member->count)
    {
      arg     = ST(2);
      ptr2[i] = SvIV(arg);
    }
    else
    {
      warn("illegal index %d", i);
    }
  }
  else if(items > 1)
  {
    arg = ST(1);
    if(SvROK(arg) && SvTYPE(SvRV(arg)) == SVt_PVAV)
    {
      av = (AV*) SvRV(arg);
      for(i=0; i < member->count; i++)
      {
        item = av_fetch(av, i, 0);
        if(item != NULL && SvOK(*item))
        {
          ptr2[i] = SvIV(*item);
        }
        else
        {
          ptr2[i] = 0;
        }
      }
    }
    else
    {
      i = SvIV(ST(1));
      if(i >= 0 && i < member->count)
      {
        XSRETURN_IV(ptr2[i]);
      }
      else
      {
        warn("illegal index %d", i);
        XSRETURN_EMPTY;
      }
    }
  }

  if(GIMME_V == G_VOID)
    XSRETURN_EMPTY;

  av = newAV();
  av_fill(av, member->count-1);
  for(i=0; i < member->count; i++)
  {
    sv_setiv(*av_fetch(av, i, 1), ptr2[i]);
  }
  ST(0) = newRV_inc((SV*)av);
  XSRETURN(1);
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

XS(ffi_pl_record_accessor_float_array)
{
  ffi_pl_record_member *member;
  SV *self;
  SV *arg;
  SV **item;
  AV *av;
  char *ptr1;
  int i;
  float *ptr2;

  dVAR; dXSARGS;

  if(items == 0)
    croak("This is a method, you must provide at least the object");

  member = (ffi_pl_record_member*) CvXSUBANY(cv).any_ptr;

  self = ST(0);
  if(SvROK(self))
    self = SvRV(self);

  ptr1 = (char*) SvPV_nolen(self);
  ptr2 = (float*) &ptr1[member->offset];

  if(items > 2)
  {
    i       = SvIV(ST(1));
    if(i >= 0 && i < member->count)
    {
      arg     = ST(2);
      ptr2[i] = SvNV(arg);
    }
    else
    {
      warn("illegal index %d", i);
    }
  }
  else if(items > 1)
  {
    arg = ST(1);
    if(SvROK(arg) && SvTYPE(SvRV(arg)) == SVt_PVAV)
    {
      av = (AV*) SvRV(arg);
      for(i=0; i < member->count; i++)
      {
        item = av_fetch(av, i, 0);
        if(item != NULL && SvOK(*item))
        {
          ptr2[i] = SvNV(*item);
        }
        else
        {
          ptr2[i] = 0.0;
        }
      }
    }
    else
    {
      i = SvIV(ST(1));
      if(i >= 0 && i < member->count)
      {
        XSRETURN_NV(ptr2[i]);
      }
      else
      {
        warn("illegal index %d", i);
        XSRETURN_EMPTY;
      }
    }
  }

  if(GIMME_V == G_VOID)
    XSRETURN_EMPTY;

  av = newAV();
  av_fill(av, member->count-1);
  for(i=0; i < member->count; i++)
  {
    sv_setnv(*av_fetch(av, i, 1), ptr2[i]);
  }
  ST(0) = newRV_inc((SV*)av);
  XSRETURN(1);
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

XS(ffi_pl_record_accessor_double_array)
{
  ffi_pl_record_member *member;
  SV *self;
  SV *arg;
  SV **item;
  AV *av;
  char *ptr1;
  int i;
  double *ptr2;

  dVAR; dXSARGS;

  if(items == 0)
    croak("This is a method, you must provide at least the object");

  member = (ffi_pl_record_member*) CvXSUBANY(cv).any_ptr;

  self = ST(0);
  if(SvROK(self))
    self = SvRV(self);

  ptr1 = (char*) SvPV_nolen(self);
  ptr2 = (double*) &ptr1[member->offset];

  if(items > 2)
  {
    i       = SvIV(ST(1));
    if(i >= 0 && i < member->count)
    {
      arg     = ST(2);
      ptr2[i] = SvNV(arg);
    }
    else
    {
      warn("illegal index %d", i);
    }
  }
  else if(items > 1)
  {
    arg = ST(1);
    if(SvROK(arg) && SvTYPE(SvRV(arg)) == SVt_PVAV)
    {
      av = (AV*) SvRV(arg);
      for(i=0; i < member->count; i++)
      {
        item = av_fetch(av, i, 0);
        if(item != NULL && SvOK(*item))
        {
          ptr2[i] = SvNV(*item);
        }
        else
        {
          ptr2[i] = 0.0;
        }
      }
    }
    else
    {
      i = SvIV(ST(1));
      if(i >= 0 && i < member->count)
      {
        XSRETURN_NV(ptr2[i]);
      }
      else
      {
        warn("illegal index %d", i);
        XSRETURN_EMPTY;
      }
    }
  }

  if(GIMME_V == G_VOID)
    XSRETURN_EMPTY;

  av = newAV();
  av_fill(av, member->count-1);
  for(i=0; i < member->count; i++)
  {
    sv_setnv(*av_fetch(av, i, 1), ptr2[i]);
  }
  ST(0) = newRV_inc((SV*)av);
  XSRETURN(1);
}

