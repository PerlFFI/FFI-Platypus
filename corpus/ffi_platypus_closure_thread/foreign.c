#ifdef _WIN32
#include <windows.h>
#else
#include <pthread.h>
#endif

#ifdef _MSC_VER
#define EXTERN extern __declspec(dllexport)
#else
#define EXTERN extern
#endif

typedef int (*callback_t)(int);

static callback_t callback;
static int callback_arg;
static int callback_ret;

#ifdef _WIN32
static DWORD WINAPI
start(LPVOID unused)
{
  callback_ret = callback(callback_arg);
  return 0;
}
#else
static void *
start(void *unused)
{
  callback_ret = callback(callback_arg);
  return NULL;
}
#endif

EXTERN int
call_in_same_thread(callback_t cb, int arg)
{
  return cb(arg);
}

EXTERN int
call_in_foreign_thread(callback_t cb, int arg)
{
  callback     = cb;
  callback_arg = arg;
  callback_ret = -1;

#ifdef _WIN32
  {
    HANDLE thread = CreateThread(NULL, 0, start, NULL, 0, NULL);
    if(thread == NULL)
      return -2;
    WaitForSingleObject(thread, INFINITE);
    CloseHandle(thread);
  }
#else
  {
    pthread_t thread;
    if(pthread_create(&thread, NULL, start, NULL) != 0)
      return -2;
    pthread_join(thread, NULL);
  }
#endif

  return callback_ret;
}
