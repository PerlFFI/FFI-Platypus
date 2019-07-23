/*
 * Philosophy: FFI dispatch should be as fast as possible considering
 * reasonable trade offs.
 *
 *  - don't allocate memory for small things using `malloc`, instead use
 *    alloca on platforms that allow it (most modern platforms do).
 *  - don't make function calls.  You shouldn't have to make a function
 *    calls to call a function.  Exceptions are for custom types and
 *    some of the more esoteric types.
 *  - one way we avoid making function calls is by putting the FFI dispatch
 *    in this header file so that it can be "called" twice without an
 *    extra function call.  (`$ffi->function(...)->call(...)` and
 *    `$ffi->attach(foo => ...); foo(...)`).  This is obviously absurd.
 *
 * Maybe all each of these weird trade offs each save only a few ms on
 * each call, but in the end the can add up.  As a result of this
 * priority set, FFI::Platypus does seem to perform considerably better
 * than any other FFI implementations available in Perl ( see
 * https://github.com/perl5-FFI/FFI-Performance ) and is even competitive
 * with XS tbh.
 */

    ffi_pl_heap *heap = NULL;


/*
#undef FFI_PL_CALL_NO_RECORD_VALUE
#undef FFI_PL_CALL_RET_NO_NORMAL
*/

#if FFI_PL_CALL_NO_RECORD_VALUE
#define RESULT &result
    ffi_pl_result result;
#elif FFI_PL_CALL_RET_NO_NORMAL
#define RESULT result_ptr
    void *result_ptr;
    Newx_or_alloca(result_ptr, self->return_type->extra[0].record_value.size, 1);
#else
#define RESULT result_ptr
    ffi_pl_result result;
    void *result_ptr;
    if(self->return_type->type_code == FFI_PL_TYPE_RECORD_VALUE)
    {
      Newx_or_alloca(result_ptr, self->return_type->extra[0].record_value.size, 1);
    }
    else
    {
      result_ptr = &result;
    }
#endif

    {
      /* buffer contains the memory required for the arguments structure */
      char *buffer;
      size_t buffer_size = sizeof(ffi_pl_argument) * self->ffi_cif.nargs +
                    sizeof(void*) * self->ffi_cif.nargs +
                    sizeof(ffi_pl_arguments);
      ffi_pl_heap_add(buffer, buffer_size, char);
      MY_CXT.current_argv = arguments = (ffi_pl_arguments*) buffer;
    }

    arguments->count = self->ffi_cif.nargs;
    argument_pointers = (void**) &arguments->slot[arguments->count];

/*
 * ARGUMENT IN
 */

    for(i=0, perl_arg_index=(EXTRA_ARGS); i < self->ffi_cif.nargs; i++, perl_arg_index++)
    {
      int type_code = self->argument_types[i]->type_code;
      argument_pointers[i] = (void*) &arguments->slot[i];

      arg = perl_arg_index < items ? ST(perl_arg_index) : &PL_sv_undef;
      switch(type_code)
      {

/*
 * ARGUMENT IN - SCALAR TYPES
 */

        case FFI_PL_TYPE_UINT8:
          ffi_pl_arguments_set_uint8(arguments, i, SvOK(arg) ? SvUV(arg) : 0);
          break;
        case FFI_PL_TYPE_SINT8:
          ffi_pl_arguments_set_sint8(arguments, i, SvOK(arg) ? SvIV(arg) : 0);
          break;
        case FFI_PL_TYPE_UINT16:
          ffi_pl_arguments_set_uint16(arguments, i, SvOK(arg) ? SvUV(arg) : 0);
          break;
        case FFI_PL_TYPE_SINT16:
          ffi_pl_arguments_set_sint16(arguments, i, SvOK(arg) ? SvIV(arg) : 0);
          break;
        case FFI_PL_TYPE_UINT32:
          ffi_pl_arguments_set_uint32(arguments, i, SvOK(arg) ? SvUV(arg) : 0);
          break;
        case FFI_PL_TYPE_SINT32:
          ffi_pl_arguments_set_sint32(arguments, i, SvOK(arg) ? SvIV(arg) : 0);
          break;
#ifdef HAVE_IV_IS_64
        case FFI_PL_TYPE_UINT64:
          ffi_pl_arguments_set_uint64(arguments, i, SvOK(arg) ? SvUV(arg) : 0);
          break;
        case FFI_PL_TYPE_SINT64:
          ffi_pl_arguments_set_sint64(arguments, i, SvOK(arg) ? SvIV(arg) : 0);
          break;
#else
        case FFI_PL_TYPE_UINT64:
          ffi_pl_arguments_set_uint64(arguments, i, SvOK(arg) ? SvU64(arg) : 0);
          break;
        case FFI_PL_TYPE_SINT64:
          ffi_pl_arguments_set_sint64(arguments, i, SvOK(arg) ? SvI64(arg) : 0);
          break;
#endif
        case FFI_PL_TYPE_FLOAT:
          ffi_pl_arguments_set_float(arguments, i, SvOK(arg) ? SvNV(arg) : 0.0);
          break;
        case FFI_PL_TYPE_DOUBLE:
          ffi_pl_arguments_set_double(arguments, i, SvOK(arg) ? SvNV(arg) : 0.0);
          break;
        case FFI_PL_TYPE_OPAQUE:
          ffi_pl_arguments_set_pointer(arguments, i, SvOK(arg) ? INT2PTR(void*, SvIV(arg)) : NULL);
          break;
        case FFI_PL_TYPE_STRING:
          ffi_pl_arguments_set_string(arguments, i, SvOK(arg) ? SvPV_nolen(arg) : NULL);
          break;
#ifdef FFI_PL_PROBE_LONGDOUBLE
        case FFI_PL_TYPE_LONG_DOUBLE:
          {
            long double *ptr;
            Newx_or_alloca(ptr, 1, long double);
            argument_pointers[i] = ptr;
            ffi_pl_perl_to_long_double(arg, ptr);
          }
          break;
#endif
#ifdef FFI_PL_PROBE_COMPLEX
        case FFI_PL_TYPE_COMPLEX_FLOAT:
          {
            float *ptr;
            Newx_or_alloca(ptr, 2, float complex);
            argument_pointers[i] = ptr;
            ffi_pl_perl_to_complex_float(arg, ptr);
          }
          break;
        case FFI_PL_TYPE_COMPLEX_DOUBLE:
          {
            double *ptr;
            Newx_or_alloca(ptr, 2, double);
            argument_pointers[i] = ptr;
            ffi_pl_perl_to_complex_double(arg, ptr);
          }
          break;
#endif
        case FFI_PL_TYPE_RECORD:
          {
            void *ptr;
            STRLEN size;
            int expected;
            expected = self->argument_types[i]->extra[0].record.size;
            if(SvROK(arg))
            {
              SV *arg2 = SvRV(arg);
              ptr = SvOK(arg2) ? SvPV(arg2, size) : NULL;
            }
            else
            {
              ptr = SvOK(arg) ? SvPV(arg, size) : NULL;
            }
            if(ptr != NULL && expected != 0 && size != expected)
              warn("record argument %d has wrong size (is %d, expected %d)", i, (int)size, expected);
            ffi_pl_arguments_set_pointer(arguments, i, ptr);
          }
          break;
        case FFI_PL_TYPE_RECORD_VALUE:
          {
            const char *record_class = self->argument_types[i]->extra[0].record_value.class;
            /* TODO if object is read-onyl ? */
            if(sv_isobject(arg) && sv_derived_from(arg, record_class))
            {
              argument_pointers[i] = SvPV_nolen(SvRV(arg));
            }
            else
            {
              ffi_pl_heap_free();
              croak("argument %d is not an instance of %s", i, record_class);
            }
          }
          break;
        case FFI_PL_TYPE_CLOSURE:
          {
            if(!SvROK(arg))
            {
              ffi_pl_arguments_set_pointer(arguments, i, SvOK(arg) ? INT2PTR(void*, SvIV(arg)) : NULL);
            }
            else
            {
              ffi_pl_closure *closure;
              ffi_status ffi_status;

              SvREFCNT_inc(arg);
              SvREFCNT_inc(SvRV(arg));

              closure = ffi_pl_closure_get_data(arg, self->argument_types[i]);
              if(closure != NULL)
              {
                ffi_pl_arguments_set_pointer(arguments, i, closure->function_pointer);
              }
              else
              {
                Newx(closure, 1, ffi_pl_closure);
                closure->ffi_closure = ffi_closure_alloc(sizeof(ffi_closure), &closure->function_pointer);
                if(closure->ffi_closure == NULL)
                {
                  Safefree(closure);
                  ffi_pl_arguments_set_pointer(arguments, i, NULL);
                  warn("unable to allocate memory for closure");
                }
                else
                {
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
                    ffi_pl_arguments_set_pointer(arguments, i, NULL);
                    warn("unable to create closure");
                  }
                  else
                  {
                    SV **svp;
                    svp = hv_fetch((HV *)SvRV(arg), "code", 4, 0);
                    if(svp != NULL)
                    {
                      closure->coderef = *svp;
                      SvREFCNT_inc(closure->coderef);
                      ffi_pl_closure_add_data(arg, closure);
                      ffi_pl_arguments_set_pointer(arguments, i, closure->function_pointer);
                    }
                    else
                    {
                      ffi_closure_free(closure->ffi_closure);
                      Safefree(closure);
                      ffi_pl_arguments_set_pointer(arguments, i, NULL);
                      warn("closure has no coderef");
                    }
                  }
                }
              }
            }
          }
          break;
        default:

          switch(type_code & FFI_PL_SHAPE_MASK)
          {

/*
 * ARGUMENT IN - POINTER TYPES
 */

            case FFI_PL_SHAPE_POINTER:
              {
                void *ptr;

                if(SvROK(arg)) /* TODO: and a scalar ref */
                {
                  SV *arg2 = SvRV(arg);
                  if(SvTYPE(arg2) < SVt_PVAV)
                  {
                    switch(type_code)
                    {
                      case FFI_PL_TYPE_UINT8 | FFI_PL_SHAPE_POINTER:
                        Newx_or_alloca(ptr, 1, uint8_t);
                        *((uint8_t*)ptr) = SvOK(arg2) ? SvUV(arg2) : 0;
                        break;
                      case FFI_PL_TYPE_SINT8 | FFI_PL_SHAPE_POINTER:
                        Newx_or_alloca(ptr, 1, int8_t);
                        *((int8_t*)ptr) = SvOK(arg2) ? SvIV(arg2) : 0;
                        break;
                      case FFI_PL_TYPE_UINT16 | FFI_PL_SHAPE_POINTER:
                        Newx_or_alloca(ptr, 1, uint16_t);
                        *((uint16_t*)ptr) = SvOK(arg2) ? SvUV(arg2) : 0;
                        break;
                      case FFI_PL_TYPE_SINT16 | FFI_PL_SHAPE_POINTER:
                        Newx_or_alloca(ptr, 1, int16_t);
                        *((int16_t*)ptr) = SvOK(arg2) ? SvIV(arg2) : 0;
                        break;
                      case FFI_PL_TYPE_UINT32 | FFI_PL_SHAPE_POINTER:
                        Newx_or_alloca(ptr, 1, uint32_t);
                        *((uint32_t*)ptr) = SvOK(arg2) ? SvUV(arg2) : 0;
                        break;
                      case FFI_PL_TYPE_SINT32 | FFI_PL_SHAPE_POINTER:
                        Newx_or_alloca(ptr, 1, int32_t);
                        *((int32_t*)ptr) = SvOK(arg2) ? SvIV(arg2) : 0;
                        break;
                      case FFI_PL_TYPE_UINT64 | FFI_PL_SHAPE_POINTER:
                        Newx_or_alloca(ptr, 1, uint64_t);
#ifdef HAVE_IV_IS_64
                        *((uint64_t*)ptr) = SvOK(arg2) ? SvUV(arg2) : 0;
#else
                        *((uint64_t*)ptr) = SvOK(arg2) ? SvU64(arg2) : 0;
#endif
                        break;
                      case FFI_PL_TYPE_SINT64 | FFI_PL_SHAPE_POINTER:
                        Newx_or_alloca(ptr, 1, int64_t);
#ifdef HAVE_IV_IS_64
                        *((int64_t*)ptr) = SvOK(arg2) ? SvIV(arg2) : 0;
#else
                        *((int64_t*)ptr) = SvOK(arg2) ? SvI64(arg2) : 0;
#endif
                        break;
                      case FFI_PL_TYPE_FLOAT | FFI_PL_SHAPE_POINTER:
                        Newx_or_alloca(ptr, 1, float);
                        *((float*)ptr) = SvOK(arg2) ? SvNV(arg2) : 0.0;
                        break;
                      case FFI_PL_TYPE_DOUBLE | FFI_PL_SHAPE_POINTER:
                        Newx_or_alloca(ptr, 1, double);
                        *((double*)ptr) = SvOK(arg2) ? SvNV(arg2) : 0.0;
                        break;
                      case FFI_PL_TYPE_OPAQUE | FFI_PL_SHAPE_POINTER:
                        Newx_or_alloca(ptr, 1, void*);
                        {
                          SV *tmp = SvRV(arg);
                          *((void**)ptr) = SvOK(tmp) ? INT2PTR(void *, SvIV(tmp)) : NULL;
                        }
                        break;
#ifdef FFI_PL_PROBE_LONGDOUBLE
                      case FFI_PL_TYPE_LONG_DOUBLE | FFI_PL_SHAPE_POINTER:
                        Newx_or_alloca(ptr, 1, long double);
                        ffi_pl_perl_to_long_double(arg2, (long double*)ptr);
                        break;
#endif
#ifdef FFI_PL_PROBE_COMPLEX
                      case FFI_PL_TYPE_COMPLEX_FLOAT | FFI_PL_SHAPE_POINTER:
                        Newx_or_alloca(ptr, 1, float complex);
                        ffi_pl_perl_to_complex_float(arg2, (float *)ptr);
                        break;
                      case FFI_PL_TYPE_COMPLEX_DOUBLE | FFI_PL_SHAPE_POINTER:
                        Newx_or_alloca(ptr, 1, double complex);
                        ffi_pl_perl_to_complex_double(arg2, (double *)ptr);
                        break;
#endif
                      case FFI_PL_TYPE_STRING | FFI_PL_SHAPE_POINTER:
                        Newx_or_alloca(ptr, 1, char *);
                        if(SvOK(arg2))
                        {
                          char *pv;
                          STRLEN len;
                          char *str;
                          pv = SvPV(arg2, len);
                          /* TODO: this should probably be a malloc since it could be arbitrarily large */
                          Newx_or_alloca(str, len+1, char);
                          memcpy(str, pv, len+1);
                          *((char**)ptr) = str;
                        }
                        else
                        {
                          *((char**)ptr) = NULL;
                        }
                        break;
                      default:
                        warn("argument type not supported (%d)", i);
                        Newx_or_alloca(ptr, 1, void*);
                        *((void**)ptr) = NULL;
                        break;
                    }
                  }
                  else
                  {
                    warn("argument type not a reference to scalar (%d)", i);
                    ptr = NULL;
                  }
                }
                else
                {
                  ptr = NULL;
                }
                ffi_pl_arguments_set_pointer(arguments, i, ptr);
              }
              break;

/*
 * ARGUMENT IN - ARRAY TYPES
 */

            case FFI_PL_SHAPE_ARRAY:
              {
                void *ptr;
                int count = self->argument_types[i]->extra[0].array.element_count;
                if(SvROK(arg) && SvTYPE(SvRV(arg)) == SVt_PVAV)
                {
                  AV *av = (AV*) SvRV(arg);
                  if(count == 0)
                    count = av_len(av)+1;
                  switch(type_code)
                  {
                    case FFI_PL_TYPE_UINT8 | FFI_PL_SHAPE_ARRAY:
                      Newx(ptr, count, uint8_t);
                      for(n=0; n<count; n++)
                      {
                        ((uint8_t*)ptr)[n] = SvUV(*av_fetch(av, n, 1));
                      }
                      break;
                    case FFI_PL_TYPE_SINT8 | FFI_PL_SHAPE_ARRAY:
                      Newx(ptr, count, int8_t);
                      for(n=0; n<count; n++)
                      {
                        ((int8_t*)ptr)[n] = SvIV(*av_fetch(av, n, 1));
                      }
                      break;
                    case FFI_PL_TYPE_UINT16 | FFI_PL_SHAPE_ARRAY:
                      Newx(ptr, count, uint16_t);
                      for(n=0; n<count; n++)
                      {
                        ((uint16_t*)ptr)[n] = SvUV(*av_fetch(av, n, 1));
                      }
                      break;
                    case FFI_PL_TYPE_SINT16 | FFI_PL_SHAPE_ARRAY:
                      Newx(ptr, count, int16_t);
                      for(n=0; n<count; n++)
                      {
                        ((int16_t*)ptr)[n] = SvIV(*av_fetch(av, n, 1));
                      }
                      break;
                    case FFI_PL_TYPE_UINT32 | FFI_PL_SHAPE_ARRAY:
                      Newx(ptr, count, uint32_t);
                      for(n=0; n<count; n++)
                      {
                        ((uint32_t*)ptr)[n] = SvUV(*av_fetch(av, n, 1));
                      }
                      break;
                    case FFI_PL_TYPE_SINT32 | FFI_PL_SHAPE_ARRAY:
                      Newx(ptr, count, int32_t);
                      for(n=0; n<count; n++)
                      {
                        ((int32_t*)ptr)[n] = SvIV(*av_fetch(av, n, 1));
                      }
                      break;
                    case FFI_PL_TYPE_UINT64 | FFI_PL_SHAPE_ARRAY:
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
                    case FFI_PL_TYPE_SINT64 | FFI_PL_SHAPE_ARRAY:
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
                    case FFI_PL_TYPE_FLOAT | FFI_PL_SHAPE_ARRAY:
                      Newx(ptr, count, float);
                      for(n=0; n<count; n++)
                      {
                        ((float*)ptr)[n] = SvNV(*av_fetch(av, n, 1));
                      }
                      break;
                    case FFI_PL_TYPE_DOUBLE | FFI_PL_SHAPE_ARRAY:
                      Newx(ptr, count, double);
                      for(n=0; n<count; n++)
                      {
                        ((double*)ptr)[n] = SvNV(*av_fetch(av, n, 1));
                      }
                      break;
                    case FFI_PL_TYPE_OPAQUE | FFI_PL_SHAPE_ARRAY:
                      Newx(ptr, count, void*);
                      for(n=0; n<count; n++)
                      {
                        SV *sv = *av_fetch(av, n, 1);
                        ((void**)ptr)[n] = SvOK(sv) ? INT2PTR(void*, SvIV(sv)) : NULL;
                      }
                      break;
#ifdef FFI_PL_PROBE_LONGDOUBLE
                    case FFI_PL_TYPE_LONG_DOUBLE | FFI_PL_SHAPE_ARRAY:
                      Newx(ptr, count, long double);
                      for(n=0; n<count; n++)
                      {
                        SV *sv = *av_fetch(av, n, 1);
                        ffi_pl_perl_to_long_double(sv, &((long double*)ptr)[n]);
                      }
                      break;
#endif
                    case FFI_PL_TYPE_STRING | FFI_PL_SHAPE_ARRAY:
                      Newx(ptr, count, char *);
                      for(n=0; n<count; n++)
                      {
                        SV *sv = *av_fetch(av, n, 1);
                        if(SvOK(sv))
                        {
                          char *str;
                          char *pv;
                          STRLEN len;
                          pv = SvPV(sv, len);
                          /* TODO: this should probably be a malloc since it could be arbitrarily large */
                          Newx_or_alloca(str, len+1, char);
                          memcpy(str, pv, len+1);
                          ((char**)ptr)[n] = str;
                        }
                        else
                        {
                          ((char**)ptr)[n] = NULL;
                        }
                      }
                      break;
                    default:
                      Newxz(ptr, count*(1 << ((type_code & FFI_PL_SIZE_MASK)-1)), char);
                      warn("argument type not supported (%d)", i);
                      break;
                  }
                }
                else
                {
                  warn("passing non array reference into ffi/platypus array argument type");
                  Newxz(ptr, count*(1 << ((type_code & FFI_PL_SIZE_MASK)-1)), char);
                }
                ffi_pl_arguments_set_pointer(arguments, i, ptr);
              }
              break;

/*
 * ARGUMENT IN - CUSTOM
 */

            case FFI_PL_SHAPE_CUSTOM_PERL:
              {
                SV *arg2 = ffi_pl_custom_perl(
                  self->argument_types[i]->extra[0].custom_perl.perl_to_native,
                  arg,
                  i
                );

                if(arg2 != NULL)
                {
                  switch(type_code)
                  {
                    case FFI_PL_TYPE_UINT8 | FFI_PL_SHAPE_CUSTOM_PERL:
                      ffi_pl_arguments_set_uint8(arguments, i, SvUV(arg2));
                      break;
                    case FFI_PL_TYPE_SINT8 | FFI_PL_SHAPE_CUSTOM_PERL:
                      ffi_pl_arguments_set_sint8(arguments, i, SvIV(arg2));
                      break;
                    case FFI_PL_TYPE_UINT16 | FFI_PL_SHAPE_CUSTOM_PERL:
                      ffi_pl_arguments_set_uint16(arguments, i, SvUV(arg2));
                      break;
                    case FFI_PL_TYPE_SINT16 | FFI_PL_SHAPE_CUSTOM_PERL:
                      ffi_pl_arguments_set_sint16(arguments, i, SvIV(arg2));
                      break;
                    case FFI_PL_TYPE_UINT32 | FFI_PL_SHAPE_CUSTOM_PERL:
                      ffi_pl_arguments_set_uint32(arguments, i, SvUV(arg2));
                      break;
                    case FFI_PL_TYPE_SINT32 | FFI_PL_SHAPE_CUSTOM_PERL:
                      ffi_pl_arguments_set_sint32(arguments, i, SvIV(arg2));
                      break;
#ifdef HAVE_IV_IS_64
                    case FFI_PL_TYPE_UINT64 | FFI_PL_SHAPE_CUSTOM_PERL:
                      ffi_pl_arguments_set_uint64(arguments, i, SvUV(arg2));
                      break;
                    case FFI_PL_TYPE_SINT64 | FFI_PL_SHAPE_CUSTOM_PERL:
                      ffi_pl_arguments_set_sint64(arguments, i, SvIV(arg2));
                      break;
#else
                    case FFI_PL_TYPE_UINT64 | FFI_PL_SHAPE_CUSTOM_PERL:
                      ffi_pl_arguments_set_uint64(arguments, i, SvU64(arg2));
                      break;
                    case FFI_PL_TYPE_SINT64 | FFI_PL_SHAPE_CUSTOM_PERL:
                      ffi_pl_arguments_set_sint64(arguments, i, SvI64(arg2));
                      break;
#endif
                    case FFI_PL_TYPE_FLOAT | FFI_PL_SHAPE_CUSTOM_PERL:
                      ffi_pl_arguments_set_float(arguments, i, SvNV(arg2));
                      break;
                    case FFI_PL_TYPE_DOUBLE | FFI_PL_SHAPE_CUSTOM_PERL:
                      ffi_pl_arguments_set_double(arguments, i, SvNV(arg2));
                      break;
                    case FFI_PL_TYPE_OPAQUE | FFI_PL_SHAPE_CUSTOM_PERL:
                      ffi_pl_arguments_set_pointer(arguments, i, SvOK(arg2) ? INT2PTR(void*, SvIV(arg2)) : NULL);
                      break;
                    default:
                      warn("argument type not supported (%d)", i);
                      break;
                  }
                  SvREFCNT_dec(arg2);
                }

                for(n=0; n < self->argument_types[i]->extra[0].custom_perl.argument_count; n++)
                {
                  i++;
                  argument_pointers[i] = &arguments->slot[i];
                }
              }
              break;

/*
 * ARGUMENT IN - OBJECT
 */

            case FFI_PL_SHAPE_OBJECT:
              {
                if(sv_isobject(arg) && sv_derived_from(arg, self->argument_types[i]->extra[0].object.class))
                {
                  SV *arg2 = SvRV(arg);
                  switch(type_code)
                  {
                    case FFI_PL_TYPE_UINT8 | FFI_PL_SHAPE_OBJECT:
                      ffi_pl_arguments_set_uint8(arguments, i, SvUV(arg2) );
                      break;
                    case FFI_PL_TYPE_SINT8 | FFI_PL_SHAPE_OBJECT:
                      ffi_pl_arguments_set_sint8(arguments, i, SvUV(arg2) );
                      break;
                    case FFI_PL_TYPE_UINT16 | FFI_PL_SHAPE_OBJECT:
                      ffi_pl_arguments_set_uint16(arguments, i, SvUV(arg2) );
                      break;
                    case FFI_PL_TYPE_SINT16 | FFI_PL_SHAPE_OBJECT:
                      ffi_pl_arguments_set_sint16(arguments, i, SvUV(arg2) );
                      break;
                    case FFI_PL_TYPE_UINT32 | FFI_PL_SHAPE_OBJECT:
                      ffi_pl_arguments_set_uint32(arguments, i, SvUV(arg2) );
                      break;
                    case FFI_PL_TYPE_SINT32 | FFI_PL_SHAPE_OBJECT:
                      ffi_pl_arguments_set_sint32(arguments, i, SvUV(arg2) );
                      break;
#ifdef HAVE_IV_IS_64
                    case FFI_PL_TYPE_UINT64 | FFI_PL_SHAPE_OBJECT:
                      ffi_pl_arguments_set_uint64(arguments, i, SvUV(arg2) );
                      break;
                    case FFI_PL_TYPE_SINT64 | FFI_PL_SHAPE_OBJECT:
                      ffi_pl_arguments_set_sint64(arguments, i, SvUV(arg2) );
                      break;
#else
                    case FFI_PL_TYPE_UINT64 | FFI_PL_SHAPE_OBJECT:
                      ffi_pl_arguments_set_uint64(arguments, i, SvU64(arg2) );
                      break;
                    case FFI_PL_TYPE_SINT64 | FFI_PL_SHAPE_OBJECT:
                      ffi_pl_arguments_set_sint64(arguments, i, SvU64(arg2) );
                      break;
#endif
                    case FFI_PL_TYPE_OPAQUE | FFI_PL_SHAPE_OBJECT:
                      ffi_pl_arguments_set_pointer(arguments, i, SvOK(arg2) ? INT2PTR(void*, SvIV(arg2)) : NULL);
                      break;
                    default:
                      ffi_pl_heap_free();
                      croak("Object argument %d type not supported %d", i, type_code);
                  }
                }
                else
                {
                  ffi_pl_heap_free();
                  croak("Object argument %d must be an object of class %s", i, self->argument_types[i]->extra[0].object.class);
                }
              }
              break;

/*
 * ARGUMENT IN - UNSUPPORTED
 */

            default:
              warn("FFI::Platypus: argument %d type not supported (%04x)", i, type_code);
              break;
          }
      }
    }

    /*
     * CALL
     */

#if 0
    fprintf(stderr, "# ===[%p]===\n", self->address);
    for(i=0; i < self->ffi_cif.nargs; i++)
    {
      fprintf(stderr, "# [%d] <%04x> %p %p",
        i,
        self->argument_types[i]->code_type,
        argument_pointers[i],
        &arguments->slot[i]
      );
      switch(self->argument_types[i]->type_code)
      {
        case FFI_PL_TYPE_LONG_DOUBLE:
          fprintf(stderr, " %Lg", *((long double*)argument_pointers[i]));
          break;
        case FFI_PL_TYPE_COMPLEX_FLOAT:
          fprintf(stderr, " %g + %g * i",
            crealf(*((float complex*)argument_pointers[i])),
            cimagf(*((float complex*)argument_pointers[i]))
          );
          break;
        case FFI_PL_TYPE_COMPLEX_DOUBLE:
          fprintf(stderr, " %g + %g * i",
            creal(*((double complex*)argument_pointers[i])),
            cimag(*((double complex*)argument_pointers[i]))
          );
          break;
        default:
          fprintf(stderr, "%016llx", ffi_pl_arguments_get_uint64(arguments, i));
          break;
      }
      fprintf(stderr, "\n");
    }
    fprintf(stderr, "# === ===\n");
    fflush(stderr);
#endif

    MY_CXT.current_argv = NULL;

    if(self->address != NULL)
    {
      ffi_call(&self->ffi_cif, self->address, RESULT, ffi_pl_arguments_pointers(arguments));
    }
    else
    {
      void *address = self->ffi_cif.nargs > 0 ? (void*) &cast1 : (void*) &cast0;
      ffi_call(&self->ffi_cif, address, RESULT, ffi_pl_arguments_pointers(arguments));
    }

/*
 * ARGUMENT OUT
 */

    MY_CXT.current_argv = arguments;

    for(i=self->ffi_cif.nargs-1,perl_arg_index--; i >= 0; i--, perl_arg_index--)
    {
      int type_code = self->argument_types[i]->type_code;

      switch(type_code)
      {

/*
 * ARGUMENT OUT - SCALAR TYPES
 */
        case FFI_PL_TYPE_CLOSURE:
          {
            arg = perl_arg_index < items ? ST(perl_arg_index) : &PL_sv_undef;
            if(SvROK(arg))
            {
              SvREFCNT_dec(arg);
              SvREFCNT_dec(SvRV(arg));
            }
          }
          break;

        default:
          switch(type_code & FFI_PL_SHAPE_MASK)
          {

/*
 * ARGUMENT OUT - POINTER TYPES
 */

            case FFI_PL_SHAPE_POINTER:
              {
                void *ptr = ffi_pl_arguments_get_pointer(arguments, i);
                if(ptr != NULL)
                {
                  arg = perl_arg_index < items ? ST(perl_arg_index) : &PL_sv_undef;
                  if(!SvREADONLY(SvRV(arg)))
                  {
                    switch(type_code)
                    {
                      case FFI_PL_TYPE_UINT8 | FFI_PL_SHAPE_POINTER:
                        sv_setuv(SvRV(arg), *((uint8_t*)ptr));
                        break;
                      case FFI_PL_TYPE_SINT8 | FFI_PL_SHAPE_POINTER:
                        sv_setiv(SvRV(arg), *((int8_t*)ptr));
                        break;
                      case FFI_PL_TYPE_UINT16 | FFI_PL_SHAPE_POINTER:
                        sv_setuv(SvRV(arg), *((uint16_t*)ptr));
                        break;
                      case FFI_PL_TYPE_SINT16 | FFI_PL_SHAPE_POINTER:
                        sv_setiv(SvRV(arg), *((int16_t*)ptr));
                        break;
                      case FFI_PL_TYPE_UINT32 | FFI_PL_SHAPE_POINTER:
                        sv_setuv(SvRV(arg), *((uint32_t*)ptr));
                        break;
                      case FFI_PL_TYPE_SINT32 | FFI_PL_SHAPE_POINTER:
                        sv_setiv(SvRV(arg), *((int32_t*)ptr));
                        break;
                      case FFI_PL_TYPE_UINT64 | FFI_PL_SHAPE_POINTER:
#ifdef HAVE_IV_IS_64
                        sv_setuv(SvRV(arg), *((uint64_t*)ptr));
#else
                        sv_setu64(SvRV(arg), *((uint64_t*)ptr));
#endif
                        break;
                      case FFI_PL_TYPE_SINT64 | FFI_PL_SHAPE_POINTER:
#ifdef HAVE_IV_IS_64
                        sv_setiv(SvRV(arg), *((int64_t*)ptr));
#else
                        sv_seti64(SvRV(arg), *((int64_t*)ptr));
#endif
                        break;
                      case FFI_PL_TYPE_FLOAT | FFI_PL_SHAPE_POINTER:
                        sv_setnv(SvRV(arg), *((float*)ptr));
                        break;
                      case FFI_PL_TYPE_OPAQUE | FFI_PL_SHAPE_POINTER:
                        if( *((void**)ptr) == NULL)
                          sv_setsv(SvRV(arg), &PL_sv_undef);
                        else
                          sv_setiv(SvRV(arg), PTR2IV(*((void**)ptr)));
                        break;
                      case FFI_PL_TYPE_DOUBLE | FFI_PL_SHAPE_POINTER:
                        sv_setnv(SvRV(arg), *((double*)ptr));
                        break;
#ifdef FFI_PL_PROBE_LONGDOUBLE
                      case FFI_PL_TYPE_LONG_DOUBLE | FFI_PL_SHAPE_POINTER:
                        ffi_pl_long_double_to_perl(SvRV(arg),(long double*)ptr);
                        break;
#endif
#ifdef FFI_PL_PROBE_COMPLEX
                      case FFI_PL_TYPE_COMPLEX_FLOAT | FFI_PL_SHAPE_POINTER:
                        ffi_pl_complex_float_to_perl(SvRV(arg), (float *)ptr);
                        break;
                      case FFI_PL_TYPE_COMPLEX_DOUBLE | FFI_PL_SHAPE_POINTER:
                        ffi_pl_complex_double_to_perl(SvRV(arg), (double *)ptr);
                        break;
#endif
                      case FFI_PL_TYPE_STRING | FFI_PL_SHAPE_POINTER:
                        {
                          char **pv = ptr;
                          if(*pv == NULL)
                          {
                            sv_setsv(SvRV(arg), &PL_sv_undef);
                          }
                          else
                          {
                            sv_setpv(SvRV(arg), *pv);
                          }
                        }
                        break;
                    }
                  }
                }
              }
              break;

/*
 * ARGUMENT OUT - ARRAY TYPES
 */

            case FFI_PL_SHAPE_ARRAY:
              {
                void *ptr = ffi_pl_arguments_get_pointer(arguments, i);
                int count = self->argument_types[i]->extra[0].array.element_count;
                arg = perl_arg_index < items ? ST(perl_arg_index) : &PL_sv_undef;
                if(SvROK(arg) && SvTYPE(SvRV(arg)) == SVt_PVAV)
                {
                  AV *av = (AV*) SvRV(arg);
                  if(count == 0)
                    count = av_len(av)+1;
                  switch(type_code)
                  {
                    case FFI_PL_TYPE_UINT8 | FFI_PL_SHAPE_ARRAY:
                      for(n=0; n<count; n++)
                      {
                        sv_setuv(*av_fetch(av, n, 1), ((uint8_t*)ptr)[n]);
                      }
                      break;
                    case FFI_PL_TYPE_SINT8 | FFI_PL_SHAPE_ARRAY:
                      for(n=0; n<count; n++)
                      {
                        sv_setiv(*av_fetch(av, n, 1), ((int8_t*)ptr)[n]);
                      }
                      break;
                    case FFI_PL_TYPE_UINT16 | FFI_PL_SHAPE_ARRAY:
                      for(n=0; n<count; n++)
                      {
                        sv_setuv(*av_fetch(av, n, 1), ((uint16_t*)ptr)[n]);
                      }
                      break;
                    case FFI_PL_TYPE_SINT16 | FFI_PL_SHAPE_ARRAY:
                      for(n=0; n<count; n++)
                      {
                        sv_setiv(*av_fetch(av, n, 1), ((int16_t*)ptr)[n]);
                      }
                      break;
                    case FFI_PL_TYPE_UINT32 | FFI_PL_SHAPE_ARRAY:
                      for(n=0; n<count; n++)
                      {
                        sv_setuv(*av_fetch(av, n, 1), ((uint32_t*)ptr)[n]);
                      }
                      break;
                    case FFI_PL_TYPE_SINT32 | FFI_PL_SHAPE_ARRAY:
                      for(n=0; n<count; n++)
                      {
                        sv_setiv(*av_fetch(av, n, 1), ((int32_t*)ptr)[n]);
                      }
                      break;
                    case FFI_PL_TYPE_UINT64 | FFI_PL_SHAPE_ARRAY:
                      for(n=0; n<count; n++)
                      {
#ifdef HAVE_IV_IS_64
                        sv_setuv(*av_fetch(av, n, 1), ((uint64_t*)ptr)[n]);
#else
                        sv_setu64(*av_fetch(av, n, 1), ((uint64_t*)ptr)[n]);
#endif
                      }
                      break;
                    case FFI_PL_TYPE_SINT64 | FFI_PL_SHAPE_ARRAY:
                      for(n=0; n<count; n++)
                      {
#ifdef HAVE_IV_IS_64
                        sv_setiv(*av_fetch(av, n, 1), ((int64_t*)ptr)[n]);
#else
                        sv_seti64(*av_fetch(av, n, 1), ((int64_t*)ptr)[n]);
#endif
                      }
                      break;
                    case FFI_PL_TYPE_FLOAT | FFI_PL_SHAPE_ARRAY:
                      for(n=0; n<count; n++)
                      {
                        sv_setnv(*av_fetch(av, n, 1), ((float*)ptr)[n]);
                      }
                      break;
                    case FFI_PL_TYPE_OPAQUE | FFI_PL_SHAPE_ARRAY:
                    case FFI_PL_TYPE_STRING | FFI_PL_SHAPE_ARRAY:
                      for(n=0; n<count; n++)
                      {
                        if( ((void**)ptr)[n] == NULL)
                        {
                          av_store(av, n, &PL_sv_undef);
                        }
                        else
                        {
                          switch(type_code) {
                            case FFI_PL_TYPE_OPAQUE | FFI_PL_SHAPE_ARRAY:
                              sv_setnv(*av_fetch(av,n,1), PTR2IV( ((void**)ptr)[n]) );
                              break;
                            case FFI_PL_TYPE_STRING | FFI_PL_SHAPE_ARRAY:
                              sv_setpv(*av_fetch(av,n,1), ((char**)ptr)[n] );
                              break;
                          }
                        }
                      }
                      break;
                    case FFI_PL_TYPE_DOUBLE | FFI_PL_SHAPE_ARRAY:
                      for(n=0; n<count; n++)
                      {
                        sv_setnv(*av_fetch(av, n, 1), ((double*)ptr)[n]);
                      }
                      break;
#ifdef FFI_PL_PROBE_LONGDOUBLE
                    case FFI_PL_TYPE_LONG_DOUBLE | FFI_PL_SHAPE_ARRAY:
                      for(n=0; n<count; n++)
                      {
                        SV *sv;
                        sv = *av_fetch(av, n, 1);
                        ffi_pl_long_double_to_perl(sv, &((long double*)ptr)[n]);
                      }
                      break;
#endif
                  }
                }
              }
              break;

/*
 * ARGUMENT OUT - CUSTOM TYPE
 */

            case FFI_PL_SHAPE_CUSTOM_PERL:
              {
                /* FIXME: need to fill out argument_types for skipping */
                i -= self->argument_types[i]->extra[0].custom_perl.argument_count;
                {
                  SV *coderef = self->argument_types[i]->extra[0].custom_perl.perl_to_native_post;
                  if(coderef != NULL)
                  {
                    arg = perl_arg_index < items ? ST(perl_arg_index) : &PL_sv_undef;
                    ffi_pl_custom_perl_cb(coderef, arg, i);
                  }
                }
              }
              break;

            default:
              break;
          }
      }
    }

    {

      int type_code = self->return_type->type_code;

      if((type_code & FFI_PL_SHAPE_MASK) != FFI_PL_SHAPE_CUSTOM_PERL)
        ffi_pl_heap_free();

      MY_CXT.current_argv = NULL;

/*
 * RETURN VALUE
 */

      switch(type_code)
      {

/*
 * RETURN VALUE - TYPE SCALAR
 */


#if ! FFI_PL_CALL_NO_RECORD_VALUE
        case FFI_PL_TYPE_RECORD_VALUE:
          {
            SV *value, *ref;
            value = sv_newmortal();
            sv_setpvn(value, result_ptr, self->return_type->extra[0].record_value.size);
            ref = ST(0) = newRV_inc(value);
            sv_bless(ref, gv_stashpv(self->return_type->extra[0].record_value.class, GV_ADD));
            XSRETURN(1);
          }
          break;
#endif
#if ! FFI_PL_CALL_RET_NO_NORMAL
        case FFI_PL_TYPE_VOID:
          XSRETURN_EMPTY;
          break;
        case FFI_PL_TYPE_UINT8:
#if defined FFI_PL_PROBE_BIGENDIAN
          XSRETURN_UV(result.uint8_array[3]);
#elif defined FFI_PL_PROBE_BIGENDIAN64
          XSRETURN_UV(result.uint8_array[7]);
#else
          XSRETURN_UV(result.uint8);
#endif
          break;
        case FFI_PL_TYPE_SINT8:
#if defined FFI_PL_PROBE_BIGENDIAN
          XSRETURN_IV(result.sint8_array[3]);
#elif defined FFI_PL_PROBE_BIGENDIAN64
          XSRETURN_IV(result.sint8_array[7]);
#else
          XSRETURN_IV(result.sint8);
#endif
          break;
        case FFI_PL_TYPE_UINT16:
#if defined FFI_PL_PROBE_BIGENDIAN
          XSRETURN_UV(result.uint16_array[1]);
#elif defined FFI_PL_PROBE_BIGENDIAN64
          XSRETURN_UV(result.uint16_array[3]);
#else
          XSRETURN_UV(result.uint16);
#endif
          break;
        case FFI_PL_TYPE_SINT16:
#if defined FFI_PL_PROBE_BIGENDIAN
          XSRETURN_IV(result.sint16_array[1]);
#elif defined FFI_PL_PROBE_BIGENDIAN64
          XSRETURN_IV(result.sint16_array[3]);
#else
          XSRETURN_IV(result.sint16);
#endif
          break;
        case FFI_PL_TYPE_UINT32:
#if defined FFI_PL_PROBE_BIGENDIAN64
          XSRETURN_UV(result.uint32_array[1]);
#else
          XSRETURN_UV(result.uint32);
#endif
          break;
        case FFI_PL_TYPE_SINT32:
#if defined FFI_PL_PROBE_BIGENDIAN64
          XSRETURN_IV(result.sint32_array[1]);
#else
          XSRETURN_IV(result.sint32);
#endif
          break;
        case FFI_PL_TYPE_UINT64:
#ifdef HAVE_IV_IS_64
          XSRETURN_UV(result.uint64);
#else
          {
            ST(0) = sv_newmortal();
            sv_setu64(ST(0), result.uint64);
            XSRETURN(1);
          }
#endif
          break;
        case FFI_PL_TYPE_SINT64:
#ifdef HAVE_IV_IS_64
          XSRETURN_IV(result.sint64);
#else
          {
            ST(0) = sv_newmortal();
            sv_seti64(ST(0), result.uint64);
            XSRETURN(1);
          }
#endif
          break;
        case FFI_PL_TYPE_FLOAT:
          XSRETURN_NV(result.xfloat);
          break;
        case FFI_PL_TYPE_DOUBLE:
          XSRETURN_NV(result.xdouble);
          break;
        case FFI_PL_TYPE_OPAQUE:
        case FFI_PL_TYPE_STRING:
          if(result.pointer == NULL)
          {
            XSRETURN_EMPTY;
          }
          else
          {
            switch(type_code)
            {
              case FFI_PL_TYPE_OPAQUE:
                XSRETURN_IV(PTR2IV(result.pointer));
                break;
              case FFI_PL_TYPE_STRING:
                XSRETURN_PV(result.pointer);
                break;
            }
          }
          break;
#ifdef FFI_PL_PROBE_LONGDOUBLE
        case FFI_PL_TYPE_LONG_DOUBLE:
        {
#if !(defined(USE_LONG_DOUBLE) && defined(HAS_LONG_DOUBLE))
          if(MY_CXT.loaded_math_longdouble == 1)
          {
            SV *sv;
            long double *ptr;
            Newx(ptr, 1, long double);
            *ptr = result.longdouble;
            sv = sv_newmortal();
            sv_setref_pv(sv, "Math::LongDouble", (void*)ptr);
            ST(0) = sv;
            XSRETURN(1);
          }
          else
          {
#endif
            XSRETURN_NV((NV) result.longdouble);
#if !(defined(USE_LONG_DOUBLE) && defined(HAS_LONG_DOUBLE))
          }
#endif
        }
#endif
#ifdef FFI_PL_PROBE_COMPLEX
        case FFI_PL_TYPE_COMPLEX_FLOAT:
          {
            SV *sv = sv_newmortal();
            ffi_pl_complex_float_to_perl(sv, (float*)&result.complex_float);
            ST(0) = sv;
            XSRETURN(1);
          }
          break;
        case FFI_PL_TYPE_COMPLEX_DOUBLE:
          {
            SV *sv = sv_newmortal();
            ffi_pl_complex_double_to_perl(sv, (double*)&result.complex_double);
            ST(0) = sv;
            XSRETURN(1);
          }
          break;
#endif
        case FFI_PL_TYPE_RECORD:
          if(result.pointer == NULL)
          {
            XSRETURN_EMPTY;
          }
          else
          {
            SV *value = sv_newmortal();
            sv_setpvn(value, result.pointer, self->return_type->extra[0].record.size);
            if(self->return_type->extra[0].record.stash)
            {
              SV *ref = ST(0) = newRV_inc(value);
              sv_bless(ref, self->return_type->extra[0].record.stash);
            }
            else
            {
              ST(0) = value;
            }
            XSRETURN(1);
          }
          break;
        case FFI_PL_SHAPE_OBJECT | FFI_PL_TYPE_OPAQUE:
          if(result.pointer == NULL)
          {
            XSRETURN_EMPTY;
          }
          else
          {
            SV *ref;
            SV *value = sv_newmortal();
            sv_setiv(value, PTR2IV(((void*)result.pointer)));
            ref = ST(0) = newRV_inc(value);
            sv_bless(ref, gv_stashpv(self->return_type->extra[0].object.class, GV_ADD));
            XSRETURN(1);
          }
          break;
        default:

          switch(type_code & FFI_PL_SHAPE_MASK)
          {

/*
 * RETURN VALUE - TYPE POINTER
 */

            case FFI_PL_SHAPE_POINTER:
              if(result.pointer == NULL)
              {
                XSRETURN_EMPTY;
              }
              else
              {
                SV *value;
                switch(type_code)
                {
                  case FFI_PL_TYPE_UINT8 | FFI_PL_SHAPE_POINTER:
                    value = sv_newmortal();
                    sv_setuv(value, *((uint8_t*) result.pointer));
                    break;
                  case FFI_PL_TYPE_SINT8 | FFI_PL_SHAPE_POINTER:
                    value = sv_newmortal();
                    sv_setiv(value, *((int8_t*) result.pointer));
                    break;
                  case FFI_PL_TYPE_UINT16 | FFI_PL_SHAPE_POINTER:
                    value = sv_newmortal();
                    sv_setuv(value, *((uint16_t*) result.pointer));
                    break;
                  case FFI_PL_TYPE_SINT16 | FFI_PL_SHAPE_POINTER:
                    value = sv_newmortal();
                    sv_setiv(value, *((int16_t*) result.pointer));
                    break;
                  case FFI_PL_TYPE_UINT32 | FFI_PL_SHAPE_POINTER:
                    value = sv_newmortal();
                    sv_setuv(value, *((uint32_t*) result.pointer));
                    break;
                  case FFI_PL_TYPE_SINT32 | FFI_PL_SHAPE_POINTER:
                    value = sv_newmortal();
                    sv_setiv(value, *((int32_t*) result.pointer));
                    break;
                  case FFI_PL_TYPE_UINT64 | FFI_PL_SHAPE_POINTER:
                    value = sv_newmortal();
#ifdef HAVE_IV_IS_64
                    sv_setuv(value, *((uint64_t*) result.pointer));
#else
                    sv_seti64(value, *((int64_t*) result.pointer));
#endif
                    break;
                  case FFI_PL_TYPE_SINT64 | FFI_PL_SHAPE_POINTER:
                    value = sv_newmortal();
#ifdef HAVE_IV_IS_64
                    sv_setiv(value, *((int64_t*) result.pointer));
#else
                    sv_seti64(value, *((int64_t*) result.pointer));
#endif
                    break;
                  case FFI_PL_TYPE_FLOAT | FFI_PL_SHAPE_POINTER:
                    value = sv_newmortal();
                    sv_setnv(value, *((float*) result.pointer));
                    break;
                  case FFI_PL_TYPE_DOUBLE | FFI_PL_SHAPE_POINTER:
                    value = sv_newmortal();
                    sv_setnv(value, *((double*) result.pointer));
                    break;
                  case FFI_PL_TYPE_OPAQUE | FFI_PL_SHAPE_POINTER:
                    value = sv_newmortal();
                    if( *((void**)result.pointer) == NULL )
                      value = &PL_sv_undef;
                    else
                      sv_setiv(value, PTR2IV(*((void**)result.pointer)));
                    break;
#ifdef FFI_PL_PROBE_LONGDOUBLE
                  case FFI_PL_TYPE_LONG_DOUBLE | FFI_PL_SHAPE_POINTER:
                    value = sv_newmortal();
                    ffi_pl_long_double_to_perl(value, (long double*)result.pointer);
                    break;
#endif
#ifdef FFI_PL_PROBE_COMPLEX
                  case FFI_PL_TYPE_COMPLEX_FLOAT | FFI_PL_SHAPE_POINTER:
                    value = sv_newmortal();
                    ffi_pl_complex_float_to_perl(value, (float*)result.pointer);
                    break;
                  case FFI_PL_TYPE_COMPLEX_DOUBLE | FFI_PL_SHAPE_POINTER:
                    value = sv_newmortal();
                    ffi_pl_complex_double_to_perl(value, (double*)result.pointer);
                    break;
#endif
                  case FFI_PL_TYPE_STRING | FFI_PL_SHAPE_POINTER:
                    value = sv_newmortal();
                    if( *((void**)result.pointer) == NULL )
                      value = &PL_sv_undef;
                    else
                      sv_setpv(value, (char*) result.pointer);
                    break;
                  default:
                    warn("return type not supported");
                    XSRETURN_EMPTY;
                }
                ST(0) = newRV_inc(value);
                XSRETURN(1);
              }
              break;

/*
 * RETURN VALUE - TYPE ARRAY
 */

            case FFI_PL_SHAPE_ARRAY:
              if(result.pointer == NULL)
              {
                XSRETURN_EMPTY;
              }
              else
              {
                int count = self->return_type->extra[0].array.element_count;
                if(count == 0 && type_code & FFI_PL_TYPE_OPAQUE)
                {
                  while(((void**)result.pointer)[count] != NULL)
                    count++;
                }
                AV *av;
                SV **sv;
                Newx(sv, count, SV*);
                switch(type_code)
                {
                  case FFI_PL_TYPE_UINT8 | FFI_PL_SHAPE_ARRAY:
                    for(i=0; i<count; i++)
                    {
                      sv[i] = newSVuv( ((uint8_t*)result.pointer)[i] );
                    }
                    break;
                  case FFI_PL_TYPE_SINT8 | FFI_PL_SHAPE_ARRAY:
                    for(i=0; i<count; i++)
                    {
                      sv[i] = newSViv( ((int8_t*)result.pointer)[i] );
                    }
                    break;
                  case FFI_PL_TYPE_UINT16 | FFI_PL_SHAPE_ARRAY:
                    for(i=0; i<count; i++)
                    {
                      sv[i] = newSVuv( ((uint16_t*)result.pointer)[i] );
                    }
                    break;
                  case FFI_PL_TYPE_SINT16 | FFI_PL_SHAPE_ARRAY:
                    for(i=0; i<count; i++)
                    {
                      sv[i] = newSViv( ((int16_t*)result.pointer)[i] );
                    }
                    break;
                  case FFI_PL_TYPE_UINT32 | FFI_PL_SHAPE_ARRAY:
                    for(i=0; i<count; i++)
                    {
                      sv[i] = newSVuv( ((uint32_t*)result.pointer)[i] );
                    }
                    break;
                  case FFI_PL_TYPE_SINT32 | FFI_PL_SHAPE_ARRAY:
                    for(i=0; i<count; i++)
                    {
                      sv[i] = newSViv( ((int32_t*)result.pointer)[i] );
                    }
                    break;
                  case FFI_PL_TYPE_UINT64 | FFI_PL_SHAPE_ARRAY:
                    for(i=0; i<count; i++)
                    {
#ifdef HAVE_IV_IS_64
                      sv[i] = newSVuv( ((uint64_t*)result.pointer)[i] );
#else
                      sv[i] = newSVu64( ((uint64_t*)result.pointer)[i] );
#endif
                    }
                    break;
                  case FFI_PL_TYPE_SINT64 | FFI_PL_SHAPE_ARRAY:
                    for(i=0; i<count; i++)
                    {
#ifdef HAVE_IV_IS_64
                      sv[i] = newSViv( ((int64_t*)result.pointer)[i] );
#else
                      sv[i] = newSVi64( ((int64_t*)result.pointer)[i] );
#endif
                    }
                    break;
                  case FFI_PL_TYPE_FLOAT | FFI_PL_SHAPE_ARRAY:
                    for(i=0; i<count; i++)
                    {
                      sv[i] = newSVnv( ((float*)result.pointer)[i] );
                    }
                    break;
                  case FFI_PL_TYPE_DOUBLE | FFI_PL_SHAPE_ARRAY:
                    for(i=0; i<count; i++)
                    {
                      sv[i] = newSVnv( ((double*)result.pointer)[i] );
                    }
                    break;
                  case FFI_PL_TYPE_STRING | FFI_PL_SHAPE_ARRAY:
                  case FFI_PL_TYPE_OPAQUE | FFI_PL_SHAPE_ARRAY:
                    for(i=0; i<count; i++)
                    {
                      if( ((void**)result.pointer)[i] == NULL)
                      {
                        sv[i] = &PL_sv_undef;
                      }
                      else
                      {
                        switch(type_code) {
                          case FFI_PL_TYPE_STRING | FFI_PL_SHAPE_ARRAY:
                            sv[i] = newSVpv( ((char**)result.pointer)[i], 0 );
                            break;
                          case FFI_PL_TYPE_OPAQUE | FFI_PL_SHAPE_ARRAY:
                            sv[i] = newSViv( PTR2IV( ((void**)result.pointer)[i] ));
                            break;
                        }
                      }
                    }
                    break;
#ifdef FFI_PL_PROBE_LONGDOUBLE
                  case FFI_PL_TYPE_LONG_DOUBLE | FFI_PL_SHAPE_ARRAY:
                    for(i=0; i<count; i++)
                    {
                      sv[i] = newSV(0);
                      ffi_pl_long_double_to_perl(sv[i], &((long double*)result.pointer)[i]);
                    }
                    break;
#endif
                  default:
                    warn("return type not supported");
                    XSRETURN_EMPTY;
                }
                av = av_make(count, sv);
                Safefree(sv);
                ST(0) = newRV_inc((SV*)av);
                XSRETURN(1);
              }
              break;

/*
 * RETURN VALUE - CUSTOM PERL
 */

            case FFI_PL_SHAPE_CUSTOM_PERL:
              {
                SV *ret_in=NULL, *ret_out;
                switch(type_code)
                {
                  case FFI_PL_TYPE_UINT8 | FFI_PL_SHAPE_CUSTOM_PERL:
#if defined FFI_PL_PROBE_BIGENDIAN
                    ret_in = newSVuv(result.uint8_array[3]);
#elif defined FFI_PL_PROBE_BIGENDIAN64
                    ret_in = newSVuv(result.uint8_array[7]);
#else
                    ret_in = newSVuv(result.uint8);
#endif
                    break;
                  case FFI_PL_TYPE_SINT8 | FFI_PL_SHAPE_CUSTOM_PERL:
#if defined FFI_PL_PROBE_BIGENDIAN
                    ret_in = newSViv(result.sint8_array[3]);
#elif defined FFI_PL_PROBE_BIGENDIAN64
                    ret_in = newSViv(result.sint8_array[7]);
#else
                    ret_in = newSViv(result.sint8);
#endif
                    break;
                  case FFI_PL_TYPE_UINT16 | FFI_PL_SHAPE_CUSTOM_PERL:
#if defined FFI_PL_PROBE_BIGENDIAN
                    ret_in = newSVuv(result.uint16_array[1]);
#elif defined FFI_PL_PROBE_BIGENDIAN64
                    ret_in = newSVuv(result.uint16_array[3]);
#else
                    ret_in = newSVuv(result.uint16);
#endif
                    break;
                  case FFI_PL_TYPE_SINT16 | FFI_PL_SHAPE_CUSTOM_PERL:
#if defined FFI_PL_PROBE_BIGENDIAN
                    ret_in = newSViv(result.sint16_array[1]);
#elif defined FFI_PL_PROBE_BIGENDIAN64
                    ret_in = newSViv(result.sint16_array[3]);
#else
                    ret_in = newSViv(result.sint16);
#endif
                    break;
                  case FFI_PL_TYPE_UINT32 | FFI_PL_SHAPE_CUSTOM_PERL:
#if defined FFI_PL_PROBE_BIGENDIAN64
                    ret_in = newSVuv(result.uint32_array[1]);
#else
                    ret_in = newSVuv(result.uint32);
#endif
                    break;
                  case FFI_PL_TYPE_SINT32 | FFI_PL_SHAPE_CUSTOM_PERL:
#if defined FFI_PL_PROBE_BIGENDIAN64
                    ret_in = newSViv(result.sint32_array[1]);
#else
                    ret_in = newSViv(result.sint32);
#endif
                    break;
                  case FFI_PL_TYPE_UINT64 | FFI_PL_SHAPE_CUSTOM_PERL:
#ifdef HAVE_IV_IS_64
                    ret_in = newSVuv(result.uint64);
#else
                    ret_in = newSVu64(result.uint64);
#endif
                    break;
                  case FFI_PL_TYPE_SINT64 | FFI_PL_SHAPE_CUSTOM_PERL:
#ifdef HAVE_IV_IS_64
                    ret_in = newSViv(result.sint64);
#else
                    ret_in = newSVi64(result.sint64);
#endif
                    break;
                  case FFI_PL_TYPE_FLOAT | FFI_PL_SHAPE_CUSTOM_PERL:
                    ret_in = newSVnv(result.xfloat);
                    break;
                  case FFI_PL_TYPE_DOUBLE | FFI_PL_SHAPE_CUSTOM_PERL:
                    ret_in = newSVnv(result.xdouble);
                    break;
                  case FFI_PL_TYPE_OPAQUE | FFI_PL_SHAPE_CUSTOM_PERL:
                    if(result.pointer != NULL)
                      ret_in = newSViv(PTR2IV(result.pointer));
                    break;
                  default:
                    ffi_pl_heap_free();
                    warn("return type not supported");
                    XSRETURN_EMPTY;
                }

                MY_CXT.current_argv = arguments;

                ret_out = ffi_pl_custom_perl(
                  self->return_type->extra[0].custom_perl.native_to_perl,
                  ret_in != NULL ? ret_in : &PL_sv_undef,
                  -1
                );

                MY_CXT.current_argv = NULL;

                ffi_pl_heap_free();

                if(ret_in != NULL)
                {
                  SvREFCNT_dec(ret_in);
                }

                if(ret_out == NULL)
                {
                  XSRETURN_EMPTY;
                }
                else
                {
                  ST(0) = sv_2mortal(ret_out);
                  XSRETURN(1);
                }

              }
              break;

            case FFI_PL_SHAPE_OBJECT:
              {
                SV *ref;
                SV *value = sv_newmortal();
                switch(type_code)
                {
                  case FFI_PL_TYPE_SINT8 | FFI_PL_SHAPE_OBJECT:
#if defined FFI_PL_PROBE_BIGENDIAN
                    sv_setiv(value, result.sint8_array[3]);
#elif defined FFI_PL_PROBE_BIGENDIAN64
                    sv_setiv(value, result.sint8_array[7]);
#else
                    sv_setiv(value, result.sint8);
#endif
                    break;
                  case FFI_PL_TYPE_UINT8 | FFI_PL_SHAPE_OBJECT:
#if defined FFI_PL_PROBE_BIGENDIAN
                    sv_setuv(value, result.uint8_array[3]);
#elif defined FFI_PL_PROBE_BIGENDIAN64
                    sv_setuv(value, result.uint8_array[7]);
#else
                    sv_setuv(value, result.uint8);
#endif
                    break;
                  case FFI_PL_TYPE_SINT16 | FFI_PL_SHAPE_OBJECT:
#if defined FFI_PL_PROBE_BIGENDIAN
                    sv_setiv(value, result.sint16_array[1]);
#elif defined FFI_PL_PROBE_BIGENDIAN64
                    sv_setiv(value, result.sint16_array[3]);
#else
                    sv_setiv(value, result.sint16);
#endif
                    break;
                  case FFI_PL_TYPE_UINT16 | FFI_PL_SHAPE_OBJECT:
#if defined FFI_PL_PROBE_BIGENDIAN
                    sv_setiv(value, result.uint16_array[1]);
#elif defined FFI_PL_PROBE_BIGENDIAN64
                    sv_setuv(value, result.uint16_array[3]);
#else
                    sv_setuv(value, result.uint16);
#endif
                    break;
                  case FFI_PL_TYPE_SINT32 | FFI_PL_SHAPE_OBJECT:
#if defined FFI_PL_PROBE_BIGENDIAN64
                    sv_setiv(value, result.sint32_array[1]);
#else
                    sv_setiv(value, result.sint32);
#endif
                    break;
                  case FFI_PL_TYPE_UINT32 | FFI_PL_SHAPE_OBJECT:
#if defined FFI_PL_PROBE_BIGENDIAN64
                    sv_setuv(value, result.uint32_array[1]);
#else
                    sv_setuv(value, result.uint32);
#endif
                    break;
                  case FFI_PL_TYPE_SINT64 | FFI_PL_SHAPE_OBJECT:
#ifdef HAVE_IV_IS_64
                    sv_setiv(value, result.sint64);
#else
                    sv_seti64(value, result.sint64);
#endif
                    break;
                  case FFI_PL_TYPE_UINT64 | FFI_PL_SHAPE_OBJECT:
#ifdef HAVE_IV_IS_64
                    sv_setuv(value, result.uint64);
#else
                    sv_setu64(value, result.sint64);
#endif
                    break;
                  default:
                    break;
                }
                ref = ST(0) = newRV_inc(value);
                sv_bless(ref, gv_stashpv(self->return_type->extra[0].object.class, GV_ADD));
                XSRETURN(1);
              }
              break;

            default:
              warn("return type not supported");
              XSRETURN_EMPTY;
              break;
          }
#endif
      }
    }

    warn("return type not supported");
    XSRETURN_EMPTY;

#undef EXTRA_ARGS
#undef FFI_PL_CALL_NO_RECORD_VALUE
#undef FFI_PL_CALL_RET_NO_NORMAL
#undef RESULT
