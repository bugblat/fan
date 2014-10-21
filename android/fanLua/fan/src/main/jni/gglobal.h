#ifndef _GGLOBAL_H_
#define _GGLOBAL_H_

#ifdef _WIN32
#ifdef GID_LIBRARY
#define G_API __declspec(dllexport)
#else
#define G_API __declspec(dllimport)
#endif
#else
#define G_API
#endif

typedef unsigned long g_id;

G_API g_id g_nextgid();

typedef void(*g_Callback)(int type, void *event, void *udata);

#endif // _GGLOBAL_H_
