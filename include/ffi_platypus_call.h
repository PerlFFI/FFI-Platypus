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

    /*
     * ARGUMENT IN
     */

    for(i=0; i<items-(EXTRA_ARGS); i++)
    {
      int platypus_type = self->argument_types[i]->platypus_type;
      ((void**)&arguments->slot[arguments->count])[i] = &arguments->slot[i];

      arg = ST(i+(EXTRA_ARGS));
      if(platypus_type == FFI_PL_FFI || platypus_type == FFI_PL_CUSTOM_PERL)
      {

        if(platypus_type == FFI_PL_CUSTOM_PERL)
        {
          dSP;
          int count;
          ENTER;
          SAVETMPS;
          PUSHMARK(SP);
          XPUSHs(arg);
          if(self->argument_types[i]->extra[0].custom_perl.userdata != NULL)
            XPUSHs((SV*)self->argument_types[i]->extra[0].custom_perl.userdata);
          PUTBACK;
          count = call_sv(self->argument_types[i]->extra[0].custom_perl.perl_to_ffi, G_SCALAR);
          SPAGAIN;
          if(count == 1)
            arg = POPs;
          else
            arg = &PL_sv_undef;
        }

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
          case FFI_TYPE_FLOAT:
            ffi_pl_arguments_set_float(arguments, i, SvNV(arg));
            break;
          case FFI_TYPE_DOUBLE:
            ffi_pl_arguments_set_double(arguments, i, SvNV(arg));
            break;
          case FFI_TYPE_POINTER:
            ffi_pl_arguments_set_pointer(arguments, i, SvOK(arg) ? INT2PTR(void*, SvIV(arg)) : NULL);
            break;
          default:
            croak("argument type not supported (%d)", i);
            break;
        }

        if(platypus_type == FFI_PL_CUSTOM_PERL)
        {
          PUTBACK;
          FREETMPS;
          LEAVE;
        }

      }
      else if(platypus_type == FFI_PL_STRING)
      {
        ffi_pl_arguments_set_string(arguments, i, SvOK(arg) ? SvPV_nolen(arg) : NULL);
      }
      else if(platypus_type == FFI_PL_POINTER)
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
              break;
            case FFI_TYPE_UINT16:
              Newx_or_alloca(ptr, uint16_t);
              *((uint16_t*)ptr) = SvUV(SvRV(arg));
              break;
            case FFI_TYPE_SINT16:
              Newx_or_alloca(ptr, int16_t);
              *((int16_t*)ptr) = SvIV(SvRV(arg));
              break;
            case FFI_TYPE_UINT32:
              Newx_or_alloca(ptr, uint32_t);
              *((uint32_t*)ptr) = SvUV(SvRV(arg));
              break;
            case FFI_TYPE_SINT32:
              Newx_or_alloca(ptr, int32_t);
              *((int32_t*)ptr) = SvIV(SvRV(arg));
              break;
            case FFI_TYPE_UINT64:
              Newx_or_alloca(ptr, uint64_t);
#ifdef HAVE_IV_IS_64
              *((uint64_t*)ptr) = SvUV(SvRV(arg));
#else
              *((uint64_t*)ptr) = SvU64(SvRV(arg));
#endif
              break;
            case FFI_TYPE_SINT64:
              Newx_or_alloca(ptr, int64_t);
#ifdef HAVE_IV_IS_64
              *((int64_t*)ptr) = SvIV(SvRV(arg));
#else
              *((int64_t*)ptr) = SvI64(SvRV(arg));
#endif
              break;
            case FFI_TYPE_FLOAT:
              Newx_or_alloca(ptr, float);
              *((float*)ptr) = SvNV(SvRV(arg));
              break;
            case FFI_TYPE_DOUBLE:
              Newx_or_alloca(ptr, double);
              *((double*)ptr) = SvNV(SvRV(arg));
              break;
            case FFI_TYPE_POINTER:
              Newx_or_alloca(ptr, void*);
              {
                SV *tmp = SvRV(arg);
                *((void**)ptr) = SvOK(tmp) ? INT2PTR(void *, SvIV(tmp)) : NULL;
              }
              break;
            default:
              croak("argument type not supported (%d)", i);
              break;
          }
        }
        else
        {
          ptr = NULL;
        }
        ffi_pl_arguments_set_pointer(arguments, i, ptr);
      }
      else if(platypus_type == FFI_PL_ARRAY)
      {
        void *ptr;
        int count = self->argument_types[i]->extra[0].array.element_count;
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
            case FFI_TYPE_UINT16:
              Newx(ptr, count, uint16_t);
              for(n=0; n<count; n++)
              {
                ((uint16_t*)ptr)[n] = SvUV(*av_fetch(av, n, 1));
              }
              break;
            case FFI_TYPE_SINT16:
              Newx(ptr, count, int16_t);
              for(n=0; n<count; n++)
              {
                ((int16_t*)ptr)[n] = SvIV(*av_fetch(av, n, 1));
              }
              break;
            case FFI_TYPE_UINT32:
              Newx(ptr, count, uint32_t);
              for(n=0; n<count; n++)
              {
                ((uint32_t*)ptr)[n] = SvUV(*av_fetch(av, n, 1));
              }
              break;
            case FFI_TYPE_SINT32:
              Newx(ptr, count, int32_t);
              for(n=0; n<count; n++)
              {
                ((int32_t*)ptr)[n] = SvIV(*av_fetch(av, n, 1));
              }
              break;
            case FFI_TYPE_UINT64:
              Newx(ptr, count, uint64_t);
              for(n=0; n<count; n++)
              {
#ifdef HAVE_IV_IS_64
                ((uint64_t*)ptr)[n] = SvUV(*av_fetch(av, n, 1));
#else
                ((uint64_t*)ptr)[n] = SvU64(*av_fetch(av, n, 1));
#endif
              }
              break;
            case FFI_TYPE_SINT64:
              Newx(ptr, count, int64_t);
              for(n=0; n<count; n++)
              {
#ifdef HAVE_IV_IS_64
                ((int64_t*)ptr)[n] = SvIV(*av_fetch(av, n, 1));
#else
                ((int64_t*)ptr)[n] = SvI64(*av_fetch(av, n, 1));
#endif
              }
              break;
            case FFI_TYPE_FLOAT:
              Newx(ptr, count, float);
              for(n=0; n<count; n++)
              {
                ((float*)ptr)[n] = SvNV(*av_fetch(av, n, 1));
              }
              break;
            case FFI_TYPE_DOUBLE:
              Newx(ptr, count, double);
              for(n=0; n<count; n++)
              {
                ((double*)ptr)[n] = SvNV(*av_fetch(av, n, 1));
              }
              break;
            case FFI_TYPE_POINTER:
              Newx(ptr, count, void*);
              for(n=0; n<count; n++)
              {
                SV *sv = *av_fetch(av, n, 1);
                ((void**)ptr)[n] = SvOK(sv) ? INT2PTR(void*, SvIV(sv)) : NULL;
              }
              break;
            default:
              croak("argument type not supported (%d)", i);
              break;
          }
        }
        else
        {
          warn("passing non array reference into ffi/platypus array argument type");
          Newxz(ptr, count*self->argument_types[i]->ffi_type->size, char);
        }
        ffi_pl_arguments_set_pointer(arguments, i, ptr);
      }
      else if(platypus_type == FFI_PL_CLOSURE)
      {
        /*
         * TODO: failing to create a closure here, should indicate a big problem
         * and sohuld be pretty rare.  That being said, it would be good to follow
         * up and see if there is any memory leaking when we croak here, or if
         * we can trigger some kind of panic to make sure the Perl process just dies.
         */
        ffi_pl_closure *closure;
        ffi_status ffi_status;
        extern void ffi_pl_closure_call(ffi_cif *, void *, void **, void *);

        Newx(closure, 1, ffi_pl_closure); /* FIXME: leak */
        closure->ffi_closure = ffi_closure_alloc(sizeof(ffi_closure), &closure->function_pointer);
        if(closure->ffi_closure == NULL)
        {
          Safefree(closure);
          croak("unable to allocate memory for closure");
        }
        closure->coderef = arg; /* TODO: should increment the count and then decrement when we come out */
        closure->type = self->argument_types[i];

        ffi_status = ffi_prep_closure_loc(
          closure->ffi_closure,
          &self->argument_types[i]->extra[0].closure.ffi_cif,
          ffi_pl_closure_call,
          closure,
          closure->function_pointer
        );

        if(ffi_status != FFI_OK)
        {
          ffi_closure_free(closure->ffi_closure);
          Safefree(closure);
          croak("unable to create closure");
        }

        ffi_pl_arguments_set_pointer(arguments, i, closure->function_pointer);
      }
      else
      {
        croak("argument type not supported (%d)", i);
      }
    }

    /*
     * CALL
     */

    if(self->address != NULL)
    {
      ffi_call(&self->ffi_cif, self->address, &result, ffi_pl_arguments_pointers(arguments));
    }
    else
    {
      void *address = items-(EXTRA_ARGS) > 0 ? (void*) &cast1 : (void*) &cast0;
      ffi_call(&self->ffi_cif, address, &result, ffi_pl_arguments_pointers(arguments));
    }

    /*
     * ARGUMENT OUT
     */

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
              case FFI_TYPE_UINT16:
                sv_setuv(SvRV(arg), *((uint16_t*)ptr));
                break;
              case FFI_TYPE_SINT16:
                sv_setiv(SvRV(arg), *((int16_t*)ptr));
                break;
              case FFI_TYPE_UINT32:
                sv_setuv(SvRV(arg), *((uint32_t*)ptr));
                break;
              case FFI_TYPE_SINT32:
                sv_setiv(SvRV(arg), *((int32_t*)ptr));
                break;
              case FFI_TYPE_UINT64:
#ifdef HAVE_IV_IS_64
                sv_setuv(SvRV(arg), *((uint64_t*)ptr));
#else
                sv_setu64(SvRV(arg), *((uint64_t*)ptr));
#endif
                break;
              case FFI_TYPE_SINT64:
#ifdef HAVE_IV_IS_64
                sv_setiv(SvRV(arg), *((int64_t*)ptr));
#else
                sv_seti64(SvRV(arg), *((int64_t*)ptr));
#endif
                break;
              case FFI_TYPE_FLOAT:
                sv_setnv(SvRV(arg), *((float*)ptr));
                break;
              case FFI_TYPE_POINTER:
                if( *((void**)ptr) == NULL)
                  sv_setsv(SvRV(arg), &PL_sv_undef);
                else
                  sv_setiv(SvRV(arg), PTR2IV(*((void**)ptr)));
                break;
              case FFI_TYPE_DOUBLE:
                sv_setnv(SvRV(arg), *((double*)ptr));
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
        arg = ST(i+(EXTRA_ARGS));
        if(SvROK(arg)) /* TODO: and a list reference */
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
            case FFI_TYPE_UINT16:
              for(n=0; n<count; n++)
              {
                sv_setuv(*av_fetch(av, n, 1), ((uint16_t*)ptr)[n]);
              }
              break;
            case FFI_TYPE_SINT16:
              for(n=0; n<count; n++)
              {
                sv_setiv(*av_fetch(av, n, 1), ((int16_t*)ptr)[n]);
              }
              break;
            case FFI_TYPE_UINT32:
              for(n=0; n<count; n++)
              {
                sv_setuv(*av_fetch(av, n, 1), ((uint32_t*)ptr)[n]);
              }
              break;
            case FFI_TYPE_SINT32:
              for(n=0; n<count; n++)
              {
                sv_setiv(*av_fetch(av, n, 1), ((int32_t*)ptr)[n]);
              }
              break;
            case FFI_TYPE_UINT64:
              for(n=0; n<count; n++)
              {
#ifdef HAVE_IV_IS_64
                sv_setuv(*av_fetch(av, n, 1), ((uint64_t*)ptr)[n]);
#else
                sv_setu64(*av_fetch(av, n, 1), ((uint64_t*)ptr)[n]);
#endif
              }
              break;
            case FFI_TYPE_SINT64:
              for(n=0; n<count; n++)
              {
#ifdef HAVE_IV_IS_64
                sv_setiv(*av_fetch(av, n, 1), ((int64_t*)ptr)[n]);
#else
                sv_seti64(*av_fetch(av, n, 1), ((int64_t*)ptr)[n]);
#endif
              }
              break;
            case FFI_TYPE_FLOAT:
              for(n=0; n<count; n++)
              {
                sv_setnv(*av_fetch(av, n, 1), ((float*)ptr)[n]);
              }
              break;
            case FFI_TYPE_POINTER:
              for(n=0; n<count; n++)
              {
                if( ((void**)ptr)[n] == NULL)
                {
                  av_store(av, n, &PL_sv_undef);
                }
                else
                {
                  sv_setnv(*av_fetch(av,n,1), PTR2IV( ((void**)ptr)[n]) );
                }
              }
              break;
            case FFI_TYPE_DOUBLE:
              for(n=0; n<count; n++)
              {
                sv_setnv(*av_fetch(av, n, 1), ((double*)ptr)[n]);
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

    /*
     * RETURN VALUE
     */

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
          case FFI_TYPE_UINT64:
#ifdef HAVE_IV_IS_64
            XSRETURN_UV((uint64_t) result);
#else
            {
              ST(0) = sv_newmortal();
              sv_setu64(ST(0), (uint64_t)result);
              XSRETURN(1);
            }
#endif
            break;
          case FFI_TYPE_SINT64:
#ifdef HAVE_IV_IS_64
            XSRETURN_IV((int64_t) result);
#else
            {
              ST(0) = sv_newmortal();
              sv_seti64(ST(0), (int64_t)result);
              XSRETURN(1);
            }
#endif
            break;
          case FFI_TYPE_FLOAT:
            XSRETURN_NV(((ffi_pl_argument*)&result)->xfloat);
            break;
          case FFI_TYPE_DOUBLE:
            XSRETURN_NV(((ffi_pl_argument*)&result)->xdouble);
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
        XSRETURN_PV((char*)result);
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
          case FFI_TYPE_UINT16:
            sv_setuv(value, *((uint16_t*) result));
            break;
          case FFI_TYPE_SINT16:
            sv_setiv(value, *((int16_t*) result));
            break;
          case FFI_TYPE_UINT32:
            sv_setuv(value, *((uint32_t*) result));
            break;
          case FFI_TYPE_SINT32:
            sv_setiv(value, *((int32_t*) result));
            break;
          case FFI_TYPE_UINT64:
#ifdef HAVE_IV_IS_64
            sv_setuv(value, *((uint64_t*) result));
#else
            sv_seti64(value, *((int64_t*) result));
#endif
            break;
          case FFI_TYPE_SINT64:
#ifdef HAVE_IV_IS_64
            sv_setiv(value, *((int64_t*) result));
#else
            sv_seti64(value, *((int64_t*) result));
#endif
            break;
          case FFI_TYPE_FLOAT:
            sv_setnv(value, *((float*) result));
            break;
          case FFI_TYPE_DOUBLE:
            sv_setnv(value, *((double*) result));
            break;
          case FFI_TYPE_POINTER:
            if( *((void**)result) == NULL )
              value = &PL_sv_undef;
            else
              sv_setiv(value, PTR2IV(*((void**)result)));
            break;
          default:
            croak("return type not supported");
        }
        ST(0) = newRV_inc(value);
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
        SV *sv[count]; /* TODO: could be large shouldn't alloate on the stack */
        switch(self->return_type->ffi_type->type)
        {
          case FFI_TYPE_UINT8:
            for(i=0; i<count; i++)
            {
              sv[i] = newSVuv( ((uint8_t*)result)[i] );
            }
            break;
          case FFI_TYPE_SINT8:
            for(i=0; i<count; i++)
            {
              sv[i] = newSViv( ((int8_t*)result)[i] );
            }
            break;
          case FFI_TYPE_UINT16:
            for(i=0; i<count; i++)
            {
              sv[i] = newSVuv( ((uint16_t*)result)[i] );
            }
            break;
          case FFI_TYPE_SINT16:
            for(i=0; i<count; i++)
            {
              sv[i] = newSViv( ((int16_t*)result)[i] );
            }
            break;
          case FFI_TYPE_UINT32:
            for(i=0; i<count; i++)
            {
              sv[i] = newSVuv( ((uint32_t*)result)[i] );
            }
            break;
          case FFI_TYPE_SINT32:
            for(i=0; i<count; i++)
            {
              sv[i] = newSViv( ((int32_t*)result)[i] );
            }
            break;
          case FFI_TYPE_UINT64:
            for(i=0; i<count; i++)
            {
#ifdef HAVE_IV_IS_64
              sv[i] = newSVuv( ((uint64_t*)result)[i] );
#else
              sv[i] = newSVu64( ((uint64_t*)result)[i] );
#endif
            }
            break;
          case FFI_TYPE_SINT64:
            for(i=0; i<count; i++)
            {
#ifdef HAVE_IV_IS_64
              sv[i] = newSViv( ((int64_t*)result)[i] );
#else
              sv[i] = newSVi64( ((int64_t*)result)[i] );
#endif
            }
            break;
          case FFI_TYPE_FLOAT:
            for(i=0; i<count; i++)
            {
              sv[i] = newSVnv( ((float*)result)[i] );
            }
            break;
          case FFI_TYPE_DOUBLE:
            for(i=0; i<count; i++)
            {
              sv[i] = newSVnv( ((double*)result)[i] );
            }
            break;
          case FFI_TYPE_POINTER:
            for(i=0; i<count; i++)
            {
              if( ((void**)result)[i] == NULL)
              {
                sv[i] = &PL_sv_undef;
              }
              else
              {
                sv[i] = newSViv( PTR2IV( ((void**)result)[i] ));
              }
            }
            break;
          default:
            croak("return type not supported");
        }
        av = av_make(count, sv);
        ST(0) = newRV_inc((SV*)av);
        XSRETURN(1);
      }
    }

    croak("return type not supported");

#undef EXTRA_ARGS
