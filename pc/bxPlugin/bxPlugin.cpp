// bxPlugin.cpp -------------------------------------------------------
//
// Copyright (c) 2001 to 2014  te
//
// Licence:     see the LICENSE.txt file
//---------------------------------------------------------------------

#include "gideros.h"
#include "lua.h"
#include "lauxlib.h"
#include "bx.h"

#include <vector>
#include <string>

using namespace std;

LUALIB_API int loader(lua_State *L);  // forward declaration

//--------------------------------------------
// an anonymous namespace holds almost all the code
namespace {
  TbxLo *handle = 0;

  //------------------------------------------
  int version(lua_State *L) {
    const char *ver = __TIME__ "," __DATE__;
    lua_pushstring(L, ver);
    return 1;
    }

  //------------------------------------------
  int addTwoIntegers(lua_State *L) {      // for testing
    int a = lua_tointeger(L, -1);
    int b = lua_tointeger(L, -2);
    lua_pushinteger(L, a+b);
    return 1;
    }

  //------------------------------------------
  void initialise(void) {
    if (handle == 0)
      handle = new TbxLo();
    }

  //------------------------------------------
  void finalise(void) {
    if (handle)
      delete handle;
    handle = 0;
    }

  //------------------------------------------
  int open(lua_State *L) {
    initialise();
    bool ok = handle->rescan();
    lua_pushboolean(L, ok);
    return 1;
    }

  //------------------------------------------
  int close(lua_State *L) {
    finalise();
    return 0;
    }

  //------------------------------------------
  int isOpen(lua_State *L) {
    bool ok = handle ? handle->isOpen() : false;
    lua_pushboolean(L, ok);
    return 1;
    }

  //------------------------------------------
  int rescan(lua_State *L) {
    bool ok = handle ? handle->rescan() : false;
    lua_pushboolean(L, ok);
    return 1;
    }

  //------------------------------------------
  int serialNumber(lua_State *L) {
    string s = handle ? handle->serialNumber() : "ERROR";
    lua_pushstring(L, s.c_str());
    return 1;
    }

  //------------------------------------------
  int ta(lua_State *L) { handle->ta(lua_tointeger(L, -1)); return 0; }
  int td(lua_State *L) { handle->td(lua_tointeger(L, -1)); return 0; }
  int tt(lua_State *L) { handle->tt(lua_tointeger(L, -1)); return 0; }
  int th(lua_State *L) { handle->th(lua_tointeger(L, -1)); return 0; }

  //------------------------------------------
  int flush(lua_State *L) {
    bool ok = handle->appFlush();
    lua_pushboolean(L, ok);
    return 1;
    }

  //------------------------------------------
  int appWrite(lua_State *L) {
    bool b = (lua_istable(L, -1) != 0);
    if (!b) {
      lua_pop(L, 1);
      lua_pushboolean(L, false);
      return 1;
      }

    size_t count = lua_objlen(L, -1);

    for (size_t i=0; i<count; i++) {
      lua_rawgeti(L, -1, i+1);
      int v = lua_tointeger(L, -1);
      handle->tx(v);
      lua_pop(L, 1);
      }
    lua_pop(L, 1);

    bool ok = handle->appFlush();
    lua_pushboolean(L, ok);

    return 1;
    }

  //------------------------------------------
  int appRead(lua_State *L) {
    size_t count   = (size_t)lua_tointeger(L, -1);

    vector<uint8_t> v;
    v.resize(count);

    bool ok = handle->appRead(&v[0], count);
    lua_pushboolean(L, ok);
    lua_pushlstring(L, (const char *)&v[0], count);

    return 2;
    }

  //------------------------------------------
  int appReadReg(lua_State *L) {
    int count  = lua_tointeger(L, -1);
    int regNum = lua_tointeger(L, -2);

    vector<uint8_t> v;
    v.resize(count);

    bool ok = handle->appReadReg(regNum, &v[0], count);
    lua_pushboolean(L, ok);
    lua_pushlstring(L, (const char *)&v[0], count);

    return 2;
    }

  //------------------------------------------
  const struct luaL_Reg functionlist[] = {
    { "version"       , version         },
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

    { NULL            , NULL            }
    };

  //--------------------------------------------
  void g_initializePlugin(lua_State* L) {
    lua_getglobal(L, "package");
    lua_getfield(L, -1, "preload");

    lua_pushcfunction(L, loader);
    lua_setfield(L, -2, "bxPlugin");

    lua_pop(L, 2);
    initialise();
    }

  //--------------------------------------------
  void g_deinitializePlugin(lua_State *L) {
    finalise();
    }

  }       // end of anonymous namespace

//--------------------------------------------
LUALIB_API int loader(lua_State *L) {
  luaL_register(L, "bx", functionlist);
  return 1;
  }

//--------------------------------------------
REGISTER_PLUGIN("bx", "1.0")

// EOF ----------------------------------------------------------------
/*
*/
