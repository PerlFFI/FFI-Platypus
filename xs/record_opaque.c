#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include "ffi_platypus.h"
#include "ffi_platypus_guts.h"

XS(ffi_pl_record_accessor_opaque)
{
  ffi_pl_record_member *member;
  SV *self;
  SV *arg;
  char *ptr1;
  void **ptr2;

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
  ptr2 = (void**) &ptr1[member->offset];

  if(items > 1)
  {
    arg = ST(1);
    *ptr2 = SvOK(arg) ? INT2PTR(void*, SvIV(arg)) : NULL;
  }

  if(GIMME_V == G_VOID)
    XSRETURN_EMPTY;

  if(*ptr2 != NULL)
    XSRETURN_IV( PTR2IV( *ptr2 ));
  else
    XSRETURN_EMPTY;
}

XS(ffi_pl_record_accessor_opaque_array)
{
  ffi_pl_record_member *member;
  SV *self;
  SV *arg;
  SV **item;
  AV *av;
  char *ptr1;
  void **ptr2;
  int i;

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
  ptr2 = (void**) &ptr1[member->offset];

  if(items > 2)
  {
    i   = SvIV(ST(1));
    if(i >= 0 && i < member->count)
    {
      arg = ST(2);
      ptr2[i] = SvOK(arg) ?  INT2PTR(void*, SvIV(arg)) : NULL;
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
          ptr2[i] = INT2PTR(void*, SvIV(*item));
        }
        else
        {
          ptr2[i] = NULL;
        }
      }
    }
    else
    {
      i   = SvIV(ST(1));
      if(i < 0 && i >= member->count)
      {
        warn("illegal index %d", i);
        XSRETURN_EMPTY;
      }
      else if(ptr2[i] == NULL)
      {
        XSRETURN_EMPTY;
      }
      else
      {
        XSRETURN_IV(PTR2IV(ptr2[i]));
      }
      warn("passing non array reference into ffi/platypus array argument type");
    }
  }

  if(GIMME_V == G_VOID)
    XSRETURN_EMPTY;

  av = newAV();
  av_fill(av, member->count-1);
  for(i=0; i < member->count; i++)
  {
    if(ptr2[i] != NULL)
      sv_setiv(*av_fetch(av, i, 1), PTR2IV(ptr2[i]));
  }
  ST(0) = newRV_inc((SV*)av);
  XSRETURN(1);
}
