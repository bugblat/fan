#ifndef GPLUGIN_H
#define GPLUGIN_H

#include "gexport.h"

#ifdef __cplusplus
extern "C" {
#endif
#include "lua.h"
#include "lualib.h"
#include "lauxlib.h"
int g_registerPlugin(void*(*plugin)(lua_State*, int));
#ifdef __cplusplus
}
#endif

#ifdef __APPLE__
#include <TargetConditionals.h>
#endif

#ifdef _WIN32
#define G_DLLEXPORT __declspec(dllexport)
#else
#define G_DLLEXPORT
#endif


#ifdef HAVE_ENTER_FRAME
#define CALL_ENTER_FRAME g_enterFrame(L)
#else
#define CALL_ENTER_FRAME
#endif


#define REGISTER_PLUGIN_STATIC_C(name, version) void REGISTER_PLUGIN_CANNOT_BE_USED_IN_C_OR_OBJC;

#define REGISTER_PLUGIN_DYNAMIC_C(name, version) \
	G_DLLEXPORT void* g_pluginMain(lua_State* L, int type) \
	{ \
		if (type == 0) \
			g_initializePlugin(L); \
		else if (type == 1) \
			g_deinitializePlugin(L); \
		else if (type == 2) \
			return (void*)name; \
		else if (type == 3) \
			return (void*)version; \
		else if (type == 4) \
			CALL_ENTER_FRAME; \
		return NULL; \
	}


#define REGISTER_PLUGIN_STATIC_CPP(name, version) \
	extern "C" { \
	static void* g_pluginMain(lua_State* L, int type) \
	{ \
		if (type == 0) \
			g_initializePlugin(L); \
		else if (type == 1) \
			g_deinitializePlugin(L); \
		else if (type == 2) \
			return (void*)name; \
		else if (type == 3) \
			return (void*)version; \
		else if (type == 4) \
			CALL_ENTER_FRAME; \
		return NULL; \
	} \
	static int g_temp = g_registerPlugin(g_pluginMain); \
	}

#define REGISTER_PLUGIN_DYNAMIC_CPP(name, version) \
	extern "C" { \
	G_DLLEXPORT void* g_pluginMain(lua_State* L, int type) \
	{ \
		if (type == 0) \
			g_initializePlugin(L); \
		else if (type == 1) \
			g_deinitializePlugin(L); \
		else if (type == 2) \
			return (void*)name; \
		else if (type == 3) \
			return (void*)version; \
		else if (type == 4) \
			CALL_ENTER_FRAME; \
		return NULL; \
	} \
	}

#if __ANDROID__
#include <jni.h>
#endif

#define REGISTER_PLUGIN_ANDROID_C(name, version) \
	G_DLLEXPORT void* g_pluginMain(lua_State* L, int type) \
	{ \
		if (type == 0) \
			g_initializePlugin(L); \
		else if (type == 1) \
			g_deinitializePlugin(L); \
		else if (type == 2) \
			return (void*)name; \
		else if (type == 3) \
			return (void*)version; \
		else if (type == 4) \
			CALL_ENTER_FRAME; \
		return NULL; \
	} \
	JNIEXPORT jint JNICALL JNI_OnLoad(JavaVM *jvm, void *reserved) \
	{ \
		g_registerPlugin(g_pluginMain); \
		return JNI_VERSION_1_6; \
	}
	
#define REGISTER_PLUGIN_ANDROID_CPP(name, version) \
	extern "C" { \
	G_DLLEXPORT void* g_pluginMain(lua_State* L, int type) \
	{ \
		if (type == 0) \
			g_initializePlugin(L); \
		else if (type == 1) \
			g_deinitializePlugin(L); \
		else if (type == 2) \
			return (void*)name; \
		else if (type == 3) \
			return (void*)version; \
		else if (type == 4) \
			CALL_ENTER_FRAME; \
		return NULL; \
	} \
	JNIEXPORT jint JNICALL JNI_OnLoad(JavaVM *jvm, void *reserved) \
	{ \
		g_registerPlugin(g_pluginMain); \
		return JNI_VERSION_1_6; \
	} \
	}
	
#ifdef __cplusplus
#define REGISTER_PLUGIN_STATIC(name, version) REGISTER_PLUGIN_STATIC_CPP(name, version)
#define REGISTER_PLUGIN_DYNAMIC(name, version) REGISTER_PLUGIN_DYNAMIC_CPP(name, version)
#define REGISTER_PLUGIN_ANDROID(name, version) REGISTER_PLUGIN_ANDROID_CPP(name, version)
#else
#define REGISTER_PLUGIN_STATIC(name, version) REGISTER_PLUGIN_STATIC_C(name, version)
#define REGISTER_PLUGIN_DYNAMIC(name, version) REGISTER_PLUGIN_DYNAMIC_C(name, version)
#define REGISTER_PLUGIN_ANDROID(name, version) REGISTER_PLUGIN_ANDROID_C(name, version)
#endif

#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
#define REGISTER_PLUGIN(name, version) REGISTER_PLUGIN_STATIC(name, version)
#elif __ANDROID__
#define REGISTER_PLUGIN(name, version) REGISTER_PLUGIN_ANDROID(name, version)
#else
#define REGISTER_PLUGIN(name, version) REGISTER_PLUGIN_DYNAMIC(name, version)
#endif

#ifdef __cplusplus
extern "C" {
#endif

GIDEROS_API void g_disableTypeChecking();
GIDEROS_API void g_enableTypeChecking();
GIDEROS_API int g_isTypeCheckingEnabled();
GIDEROS_API void g_createClass(lua_State* L,
								 const char* classname,
								 const char* basename,
								 int (*constructor) (lua_State*),
								 int (*destructor) (lua_State*),
								 const luaL_reg* functionlist);
GIDEROS_API void g_pushInstance(lua_State* L, const char* classname, void* ptr);
GIDEROS_API void* g_getInstance(lua_State* L, const char* classname, int index);
GIDEROS_API void g_setInstance(lua_State* L, int index, void* ptr);
GIDEROS_API int g_isInstanceOf(lua_State* L, const char* classname, int index);

GIDEROS_API int g_error(lua_State* L, const char* msg);


#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
#ifdef __OBJC__
@class UIViewController;
UIViewController* g_getRootViewController();
#endif
#endif

#ifdef __cplusplus
}
#endif



#endif
