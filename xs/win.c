#if defined(_WIN32) || defined(__CYGWIN__)

#include <windows.h>
#if defined(__CYGWIN__)
#include <sys/cygwin.h>
#endif
#include <string.h>
#include <psapi.h>
#include <ffi_pl.h>

struct _ffi_pl_system_library_handle {
  int is_null; 
  int flags;
  HMODULE os_handle;
};

static const char *error = NULL;

ffi_pl_system_library_handle*
ffi_pl_windows_dlopen(const char *filename, int flags)
{
  ssize_t size;
  char *win_path_filename;
  ffi_pl_system_library_handle *handle;

  win_path_filename = NULL;
  
#if defined(__CYGWIN__)
  if(filename != NULL)
  {
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
  
  handle = malloc(sizeof(ffi_pl_system_library_handle));
  
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
  return handle;
}

static int         last_flag = 0;
static const char *last_mod_name = NULL;
static HMODULE     last_library_handle = NULL;

int
ffi_pl_windows_dlsym_win32_meta(const char **mod_name, void **mod_handle)
{
  if(!last_flag)
    return 0;

  if(mod_name != NULL)
    *mod_name = last_mod_name;
  if(mod_handle != NULL)
    *mod_handle = last_library_handle;
  else
    FreeLibrary(last_library_handle);
  return 1;
}

void *
ffi_pl_windows_dlsym(ffi_pl_system_library_handle *handle, const char *symbol_name)
{
  static const char *not_found = "symbol not found";
  void *symbol;

  last_flag = 0;
  last_mod_name = NULL;
  last_library_handle = NULL;

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
            /* TODO: FreeLibrary never gets called on handle */
            last_mod_name = mod_name;
            last_library_handle = handle;
            last_flag = 1;
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

const char *
ffi_pl_windows_dlerror(void)
{
  return error;
}

int
ffi_pl_windows_dlclose(ffi_pl_system_library_handle *handle)
{
  if(!handle->is_null)
  {
    FreeLibrary(handle->os_handle);
  }
  error = NULL;
  return 0;
}

#else

int
ffi_pl_windows_dlsym_win32_meta(const char **mod_name, void **mod_handle)
{
  return 0;
}

#endif
