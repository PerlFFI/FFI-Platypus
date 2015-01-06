    if(items-(EXTRA_ARGS) != self->ffi_cif.nargs)
      croak("wrong number of arguments (expected %d, got %d)", self->ffi_cif.nargs, items-(EXTRA_ARGS) );

    buffer_size = sizeof(ffi_pl_argument) * self->ffi_cif.nargs * 2 + sizeof(ffi_pl_arguments);
#ifdef HAVE_ALLOCA
    buffer = alloca(buffer_size);
#else
    Newx(buffer, buffer_size, char);
#endif
    arguments = (ffi_pl_arguments*) buffer;

    arguments->count = self->ffi_cif.nargs;

    for(i=0; i<items-(EXTRA_ARGS); i++)
    {
      ((void**)&arguments->slot[arguments->count])[i] = &arguments->slot[i];

      arg = ST(i+(EXTRA_ARGS));
      if(self->argument_types[i]->platypus_type == FFI_PL_FFI)
      {
        switch(self->argument_types[i]->ffi_type->type)
        {
          case FFI_TYPE_UINT8:
            ffi_pl_arguments_set_uint8(arguments, i, SvUV(arg));
            break;
          case FFI_TYPE_SINT8:
            ffi_pl_arguments_set_sint8(arguments, i, SvIV(arg));
            break;
          case FFI_TYPE_UINT16:
            ffi_pl_arguments_set_uint16(arguments, i, SvUV(arg));
            break;
          case FFI_TYPE_SINT16:
            ffi_pl_arguments_set_sint16(arguments, i, SvIV(arg));
            break;
          case FFI_TYPE_UINT32:
            ffi_pl_arguments_set_uint32(arguments, i, SvUV(arg));
            break;
          case FFI_TYPE_SINT32:
            ffi_pl_arguments_set_sint32(arguments, i, SvIV(arg));
            break;
#ifdef HAVE_IV_IS_64
          case FFI_TYPE_UINT64:
            ffi_pl_arguments_set_uint64(arguments, i, SvUV(arg));
            break;
          case FFI_TYPE_SINT64:
            ffi_pl_arguments_set_sint64(arguments, i, SvIV(arg));
            break;
#else
          case FFI_TYPE_UINT64:
            ffi_pl_arguments_set_uint64(arguments, i, SvU64(arg));
            break;
          case FFI_TYPE_SINT64:
            ffi_pl_arguments_set_sint64(arguments, i, SvI64(arg));
            break;
#endif
          case FFI_TYPE_POINTER:
            ffi_pl_arguments_set_pointer(arguments, i, SvOK(arg) ? INT2PTR(void*, SvIV(arg)) : NULL);
            break;
        }
      }
      else if(self->argument_types[i]->platypus_type == FFI_PL_STRING)
      {
        ffi_pl_arguments_set_string(arguments, i, SvOK(arg) ? SvPV_nolen(arg) : NULL);
      }
      else if(self->argument_types[i]->platypus_type == FFI_PL_POINTER)
      {
        void *ptr;
        if(SvROK(arg)) /* TODO: and a scalar ref */
        {
          switch(self->argument_types[i]->ffi_type->type)
          {
            case FFI_TYPE_UINT8:
              Newx_or_alloca(ptr, uint8_t);
              *((uint8_t*)ptr) = SvUV(SvRV(arg));
              break;
            case FFI_TYPE_SINT8:
              Newx_or_alloca(ptr, int8_t);
              *((int8_t*)ptr) = SvIV(SvRV(arg));
          }
        }
        else
        {
          ptr = NULL;
        }
        ffi_pl_arguments_set_pointer(arguments, i, ptr);
      }
      else if(self->argument_types[i]->platypus_type == FFI_PL_ARRAY)
      {
        void *ptr;
        int count = self->argument_types[i]->extra[0].array.element_count;
        int n;
        if(SvROK(arg)) /* TODO: and an array ref */
        {
          AV *av = (AV*) SvRV(arg);
          switch(self->argument_types[i]->ffi_type->type)
          {
            case FFI_TYPE_UINT8:
              Newx(ptr, count, uint8_t);
              for(n=0; n<count; n++)
              {
                ((uint8_t*)ptr)[n] = SvUV(*av_fetch(av, n, 1));
              }
              break;
            case FFI_TYPE_SINT8:
              Newx(ptr, count, int8_t);
              for(n=0; n<count; n++)
              {
                ((int8_t*)ptr)[n] = SvIV(*av_fetch(av, n, 1));
              }
              break;
          }
        }
        else
        {
          ptr = NULL;
        }
        ffi_pl_arguments_set_pointer(arguments, i, ptr);
      }
    }

    ffi_call(&self->ffi_cif, self->address, &result, ffi_pl_arguments_pointers(arguments));

    for(i=0; i<items-(EXTRA_ARGS); i++)
    {
      if(self->argument_types[i]->platypus_type == FFI_PL_POINTER)
      {
        void *ptr = ffi_pl_arguments_get_pointer(arguments, i);
        if(ptr != NULL)
        {
          arg = ST(i+(EXTRA_ARGS));
          if(!SvREADONLY(SvRV(arg)))
          {
            switch(self->argument_types[i]->ffi_type->type)
            {
              case FFI_TYPE_UINT8:
                sv_setuv(SvRV(arg), *((uint8_t*)ptr));
                break;
              case FFI_TYPE_SINT8:
                sv_setiv(SvRV(arg), *((int8_t*)ptr));
                break;
            }
          }
        }
#ifndef HAVE_ALLOCA
        Safefree(ptr);
#endif
      }

      if(self->argument_types[i]->platypus_type == FFI_PL_ARRAY)
      {
        void *ptr = ffi_pl_arguments_get_pointer(arguments, i);
        int count = self->argument_types[i]->extra[0].array.element_count;
        int n;
        if(ptr != NULL)
        {
          AV *av = (AV*) SvRV(arg);
          switch(self->argument_types[i]->ffi_type->type)
          {
            case FFI_TYPE_UINT8:
              for(n=0; n<count; n++)
              {
                sv_setuv(*av_fetch(av, n, 1), ((uint8_t*)ptr)[n]);
              }
              break;
            case FFI_TYPE_SINT8:
              for(n=0; n<count; n++)
              {
                sv_setiv(*av_fetch(av, n, 1), ((int8_t*)ptr)[n]);
              }
              break;
          }
        }
#ifndef HAVE_ALLOCA
        Safefree(ptr);
#endif
      }
    }
#ifndef HAVE_ALLOCA
    Safefree(buffer);
#endif

    if(self->return_type->platypus_type == FFI_PL_FFI)
    {
      int type = self->return_type->ffi_type->type;
      if(type == FFI_TYPE_VOID || (type == FFI_TYPE_POINTER && ((void*) result) == NULL))
      {
        XSRETURN_EMPTY;
      }
      else
      {
        switch(self->return_type->ffi_type->type)
        {
          case FFI_TYPE_UINT8:
            XSRETURN_UV((uint8_t) result);
            break;
          case FFI_TYPE_SINT8:
            XSRETURN_IV((int8_t) result);
            break;
          case FFI_TYPE_UINT16:
            XSRETURN_UV((uint16_t) result);
            break;
          case FFI_TYPE_SINT16:
            XSRETURN_IV((int16_t) result);
            break;
          case FFI_TYPE_UINT32:
            XSRETURN_UV((uint32_t) result);
            break;
          case FFI_TYPE_SINT32:
            XSRETURN_IV((int32_t) result);
            break;
          case FFI_TYPE_POINTER:
            XSRETURN_IV(PTR2IV((void*)result));
            break;
        }
      }
    }
    else if(self->return_type->platypus_type == FFI_PL_STRING)
    {
      if( ((char*)result) == NULL )
      {
        XSRETURN_EMPTY;
      }
      else
      {
        arg = ST(0) = sv_newmortal();
        sv_setpv(arg, (char*)result);
      }
    }
    else if(self->return_type->platypus_type == FFI_PL_POINTER)
    {
      void *ptr = (void*) result;
      if(ptr == NULL)
      {
        XSRETURN_EMPTY;
      }
      else
      {
        SV *value = sv_newmortal();
        switch(self->return_type->ffi_type->type)
        {
          case FFI_TYPE_UINT8:
            sv_setuv(value, *((uint8_t*) result));
            break;
          case FFI_TYPE_SINT8:
            sv_setiv(value, *((int8_t*) result));
            break;
        }
        arg = ST(0) = newRV_inc(value);
        XSRETURN(1);
      }
    }
    else if(self->return_type->platypus_type == FFI_PL_ARRAY)
    {
      void *ptr = (void*) result;
      if(ptr == NULL)
      {
        XSRETURN_EMPTY;
      }
      else
      {
        int count = self->return_type->extra[0].array.element_count;
        AV *av;
        switch(self->return_type->ffi_type->type)
        {
          croak("todo");
          case FFI_TYPE_UINT8:
            for(i=0; i<count; i++)
            {
            }
            break;
        }
      }
    }


#undef EXTRA_ARGS
