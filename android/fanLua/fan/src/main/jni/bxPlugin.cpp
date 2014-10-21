#include <vector>

#include "gideros.h"
#include "lua.h"
#include "lauxlib.h"

#define LUA_LIB
#include <jni.h>

#include <android/log.h>

using namespace std;

LUALIB_API int loader(lua_State *L);

//--------------------------------------------
namespace {
  const char *pluginNAME    = "bxPlugin";
  const char *pluginTABLE   = "bx";
  const char *pluginVERSION = "1.0";

  JNIEnv    *ENV = 0;             // Store Java Environment reference
  jclass    cls  = 0;             // Store our main class, what we will use as plugin

  //--------------------------------------------
  const char* javaClassName = "com/giderosmobile/android/bxPlugin";
  bool getMethodID(jmethodID& aMethodID, const char *aName, const char *aArgSig) {
    __android_log_print(ANDROID_LOG_DEBUG, "getMethodID", "module:%s", aName);

    if (ENV == 0)                 // exit if no Java Env
      return false;

    if (cls == 0) {               // if no class, try to retrieve it
      cls = ENV->FindClass(javaClassName);
      if(!cls)
        return false;
      }

    if (aMethodID == 0) {
      /****************
      * 1. argument cls - reference to Java class, where we have this method
      * 2. argument name of the method to get
      * 3. argument what arguments does method accept and what it returns
        ****************/
      aMethodID = ENV->GetStaticMethodID(cls, aName, aArgSig);
      }
    return (aMethodID != 0);
    }

  //------------------------------------------
  int version(lua_State *L) {
    const char *ver = __TIME__ "," __DATE__;
    lua_pushstring(L, ver);
    return 1;
    }

  //--------------------------------------------
  int addTwoIntsLoc(lua_State *L) {       // for testing
    int a = lua_tointeger(L, -1);
    int b = lua_tointeger(L, -2);
    lua_pushnumber(L, a+b);
    return 1;
    }

  //--------------------------------------------
  int addTwoIntegers(lua_State *L) {      // for testing
    static jmethodID methodID = 0;
    int a = lua_tointeger(L, -1);
    int b = lua_tointeger(L, -2);
    int result = 9999;

    if (getMethodID(methodID, "addTwoIntegers", "(II)I")) {
      result = ENV->CallStaticIntMethod(cls, methodID, a, b);
      }
    lua_pushnumber(L, result);
    return 1;
    }

  //------------------------------------------
  int open(lua_State *L) {
    static jmethodID methodID = 0;
    bool ok = false;
    if (getMethodID(methodID, "open", "()Z")) {
      ok = ENV->CallStaticBooleanMethod(cls, methodID);
      }
    lua_pushboolean(L, ok);
    return 1;
    }

  //------------------------------------------
  int close(lua_State *L) {
    static jmethodID methodID = 0;
    if (getMethodID(methodID, "close", "()V")) {
      ENV->CallStaticVoidMethod(cls, methodID);
      }
    return 0;
    }

  //------------------------------------------
  int isOpen(lua_State *L) {
    static jmethodID methodID = 0;
    bool ok = false;
    if (getMethodID(methodID, "isOpen", "()Z")) {
      ok = ENV->CallStaticBooleanMethod(cls, methodID);
      }
    lua_pushboolean(L, ok);
    return 1;
    }

  //------------------------------------------
  int rescan(lua_State *L) {
    static jmethodID methodID = 0;
    bool ok = false;
    if (getMethodID(methodID, "rescan", "()Z")) {
      ok = ENV->CallStaticBooleanMethod(cls, methodID);
      }
    lua_pushboolean(L, ok);
    return 1;
    }

  //------------------------------------------
  int serialNumber(lua_State *L) {
    char *s = (char *)("ERROR");
    static jmethodID methodID = 0;
    if (getMethodID(methodID, "serialNumber", "()Ljava/lang/String;")) {
      jstring jstr = (jstring)ENV->CallStaticObjectMethod(cls, methodID);
      s = (char *)ENV->GetStringUTFChars(jstr, 0);
      }
    lua_pushlstring(L, s, strlen(s));
    return 1;
    }

  //--------------------------------------------
  int ta(lua_State *L) {
    static jmethodID methodID = 0;
    if (getMethodID(methodID, "ta", "(I)V")) {
      int v = lua_tointeger(L, -1);
      ENV->CallStaticVoidMethod(cls, methodID, v);
      }
    return 0;
    }

  //--------------------------------------------
  int td(lua_State *L) {
    static jmethodID methodID = 0;
    if (getMethodID(methodID, "td", "(I)V")) {
      int v = lua_tointeger(L, -1);
      ENV->CallStaticVoidMethod(cls, methodID, v);
      }
    return 0;
    }

  //--------------------------------------------
  int tt(lua_State *L) {
    static jmethodID methodID = 0;
    if (getMethodID(methodID, "tt", "(I)V")) {
      int v = lua_tointeger(L, -1);
      ENV->CallStaticVoidMethod(cls, methodID, v);
      }
    return 0;
    }

  //--------------------------------------------
  int th(lua_State *L) {
    static jmethodID methodID = 0;
    if (getMethodID(methodID, "th", "(I)V")) {
      int v = lua_tointeger(L, -1);
      ENV->CallStaticVoidMethod(cls, methodID, v);
      }
    return 0;
    }

  //------------------------------------------
  int flush(lua_State *L) {
    static jmethodID methodID = 0;
    bool ok = false;
    if (getMethodID(methodID, "appFlush", "()Z")) {
      ok = ENV->CallStaticBooleanMethod(cls, methodID);
      }
    lua_pushboolean(L, ok);
    return 1;
    }

  //------------------------------------------
  int appWrite(lua_State *L) {
    static jmethodID methodID = 0;
    bool b = (lua_istable(L, -1) != 0);
    if (!b) {
      lua_pop(L, 1);
      lua_pushboolean(L, false);
      return 1;
      }

    size_t count = lua_objlen(L, -1);
    vector<uint8_t> vec;
    vec.resize(count);

    for (size_t i=0; i<count; i++) {
      lua_rawgeti(L, -1, i+1);
      int v = lua_tointeger(L, -1);
      vec.push_back(v);
      lua_pop(L, 1);
      }
    lua_pop(L, 1);

    bool ok = false;
    if (getMethodID(methodID, "appWrite", "([BI)Z")) {
      jbyteArray jBuff = ENV->NewByteArray(count);
      ENV->SetByteArrayRegion(jBuff, 0, count, (jbyte *)&vec[0]);

      ok = ENV->CallStaticBooleanMethod(cls, methodID, jBuff, count);
      ENV->DeleteLocalRef(jBuff);
      }
    lua_pushboolean(L, ok);
    return 1;
    }

  //------------------------------------------
  int appRead(lua_State *L) {
    int count = lua_tointeger(L, -1);

    static jmethodID methodID = 0;
    if (getMethodID(methodID, "appRead", "(I)[B")) {
      jbyteArray jBuff = (jbyteArray)ENV->CallStaticObjectMethod(cls, methodID, count);
      int retlen = ENV->GetArrayLength(jBuff);
      char *buf = new char[retlen];
      ENV->GetByteArrayRegion (jBuff, 0, retlen, reinterpret_cast<jbyte*>(buf));
      lua_pushboolean(L, true);
      lua_pushlstring(L, buf, retlen);
      delete[] buf;
      }
    else {
      lua_pushboolean(L, false);
      const char *s = "ERROR";
      lua_pushlstring(L, s, sizeof(s));
      }

    return 2;
    }

  //------------------------------------------
  int appReadReg(lua_State *L) {
    int count  = lua_tointeger(L, -1);
    int regNum = lua_tointeger(L, -2);

    static jmethodID methodID = 0;
    if (getMethodID(methodID, "appReadReg", "(II)[B")) {
      jbyteArray jBuff = (jbyteArray)ENV->CallStaticObjectMethod(cls, methodID, regNum, count);
      int retlen = ENV->GetArrayLength(jBuff);
      char *buf = new char[retlen];
      ENV->GetByteArrayRegion (jBuff, 0, retlen, reinterpret_cast<jbyte*>(buf));
      lua_pushboolean(L, true);
      lua_pushlstring(L, buf, retlen);
      delete[] buf;
      }
    else {
      lua_pushboolean(L, false);
      const char *s = "ERROR";
      lua_pushlstring(L, s, sizeof(s));
      }

    return 2;
    }

  //------------------------------------------
  const struct luaL_Reg functionList[] = {
    { "version"       , version         },
    { "addTwoIntsLoc" , addTwoIntsLoc   },
    { "addTwoIntegers", addTwoIntegers  },

    { "open"          , open            },
    { "close"         , close           },
    { "isOpen"        , isOpen          },
    { "rescan"        , rescan          },
    { "serialNumber"  , serialNumber    },

    { "ta"            , ta              },
    { "td"            , td              },
    { "tt"            , tt              },
    { "th"            , th              },
    { "flush"         , flush           },

    { "write"         , appWrite        },
    { "read"          , appRead         },
    { "readReg"       , appReadReg      },

    { 0               , 0               }
    };

  //--------------------------------------------
  void g_initializePlugin(lua_State* L) {
    ENV = g_getJNIEnv();

    lua_getglobal(L, "package");
    lua_getfield(L, -1, "preload");

    lua_pushcfunction(L, loader);
    lua_setfield(L, -2, pluginNAME);

    lua_pop(L, 2);
    }

  //--------------------------------------------
  void g_deinitializePlugin(lua_State *L) {}

  }       // end of anonymous namespace

//----------------------------------------------
LUALIB_API int loader(lua_State *L) {
  //__android_log_print(ANDROID_LOG_DEBUG, "bxPlugin", "loader called");
  luaL_register(L, pluginTABLE, functionList);
  return 1;
  }

//--------------------------------------------
REGISTER_PLUGIN(pluginTABLE, pluginVERSION)

// EOF ----------------------------------------------------------------
/*
*/
