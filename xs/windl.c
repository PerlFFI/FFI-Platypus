#include <ffi_platypus.h>

#ifdef PERL_OS_WINDOWS

#ifdef HAVE_WINDOWS_H
#include <windows.h>
#endif
#ifdef HAVE_SYS_CYGWIN_H
#include <sys/cygwin.h>
#endif
#ifdef HAVE_STRING_H
#include <string.h>
#endif
/*
 * TODO: c::ac is not detecting psapi.h for some reason ...
 * but it should always be there in any platform that
 * we support
 */
#include <psapi.h>

typedef struct _library_handle {
  int is_null;
  int flags;
  HMODULE os_handle;
} library_handle;

static const char *error = NULL;

/*
 * dlopen()
 */

void *
windlopen(const char *filename, int flags)
{
  char *win_path_filename;
  library_handle *handle;
  
  win_path_filename = NULL;

#ifdef PERL_OS_CYGWIN
  if(filename != NULL)
  {
    ssize_t size;
    size = cygwin_conv_path(CCP_POSIX_TO_WIN_A | CCP_RELATIVE, filename, NULL, 0);
    if(size < 0)
    {
      error = "unable to determine length of string for cygwin_conv_path";
      return NULL;
    }
    win_path_filename = malloc(size);
    if(win_path_filename == NULL)
    {
      error = "unable to allocate enough memory for cygwin_conv_path";
      return NULL;
    }
    if(cygwin_conv_path(CCP_POSIX_TO_WIN_A | CCP_RELATIVE, filename, win_path_filename, size))
    {
      error = "error in conversion for cygwin_conv_path";
      free(win_path_filename);
      return NULL;
    }
    filename = win_path_filename;
  }
#endif

  handle = malloc(sizeof(library_handle));
  
  if(handle == NULL)
  {
    if(win_path_filename != NULL)
      free(win_path_filename);
    error = "unable to allocate memory for handle";
    return NULL;
  }
  
  if(filename == NULL)
  {
    handle->is_null = 1;
  }
  else
  {
    handle->is_null = 0;
    handle->os_handle = LoadLibrary(filename);
  }
  
  handle->flags = flags;
  
  if(win_path_filename != NULL)
    free(win_path_filename);
  error = NULL;
  return (void*) handle;
}

/*
 * dlsym()
 */

void *
windlsym(void *void_handle, const char *symbol_name)
{
  library_handle *handle = (library_handle*) void_handle;
  static const char *not_found = "symbol not found";
  void *symbol;
  
  if(!handle->is_null)
  {
    symbol = GetProcAddress(handle->os_handle, symbol_name);
    if(symbol == NULL)
      error = not_found;
    else
      error = NULL;
    return symbol;
  }
  else
  {
    int n;
    DWORD needed;
    HANDLE process;
    HMODULE mods[1024];
    TCHAR mod_name[MAX_PATH];
    
    process = OpenProcess(
      PROCESS_QUERY_INFORMATION | PROCESS_VM_READ,
      FALSE, GetCurrentProcessId()
    );
    
    if(process == NULL)
    {
      error = "Process for self not found";
      return NULL;
    }
    
    if(EnumProcessModules(process, mods, sizeof(mods), &needed))
    {
      for(n=0; n < (needed/sizeof(HMODULE)); n++)
      {
        if(GetModuleFileNameEx(process, mods[n], mod_name, sizeof(mod_name) / sizeof(TCHAR)))
        {
          HMODULE handle = LoadLibrary(mod_name);
          if(handle == NULL)
            continue;
          symbol = GetProcAddress(handle, symbol_name);
          
          if(symbol != NULL)
          {
            error = NULL;
            FreeLibrary(handle);
            return symbol;
          }
          
          FreeLibrary(handle);
        }
      }
    }
    error = not_found;
    return NULL;
  }
}

/*
 * dlerror()
 */

const char *
windlerror(void)
{
  return error;
}

/*
 * dlclose()
 */

int
windlclose(void *void_handle)
{
  library_handle *handle = (library_handle*) void_handle;
  if(!handle->is_null)
  {
    FreeLibrary(handle->os_handle);
  }
  free(handle);
  error = NULL;
  return 0;
}

#endif
