// libbx.h -----------------------------------------------------------
//
// Copyright (c) 2001 to 2014  te
//
// a C wrapper for the bx low-level code
//
// Licence:     see the LICENSE.txt file
//---------------------------------------------------------------------
#ifndef libbxH
#define libbxH

#include <stdint.h>
#include "bxdefs.h"

// Add '-DBUILDING_LIBBX' and '-fvisibility=hidden' to the makefile flags

//--------------------------------------------
#define VID_FT            0x0403          /* FTDI vendor ID */
#define PID_FT230         0x6015          /* FTDI FT230 PID */

#define ID_XO2_2000HC     0x012bb043

//--------------------------------------------
// sub-addresses to the FPGA logic
#define A_ADDR   (0<<6)     /* sending an address */
#define D_ADDR   (1<<6)     /* sending data       */
#define T_ADDR   (2<<6)     /* sending 6 count bits and trigger readback */
#define H_ADDR   (3<<6)     /* sending 6 count bits, no readback */

//---------------------------------------------------------------------
// routines from the FTDI driver interface
#define OP_FtListDevices                           1
#define OP_FtOpenEx                                2
#define OP_FtClose                                 3
#define OP_FtPurge                                 4
#define OP_FtSetTimeouts                           5
#define OP_FtRead                                  6
#define OP_FtWrite                                 7
#define OP_FtSetUSBParameters                      8
#define OP_FtSetLatencyTimer                       9
#define OP_FtGetLatencyTimer                      10

//--------------------------------------------
#if defined _WIN32 || defined __CYGWIN__
  #define BX_LO_DLL_IMPORT __declspec(dllimport)
  #define BX_LO_DLL_EXPORT __declspec(dllexport)
  #define BX_LO_DLL_LOCAL
#else
  #if __GNUC__ >= 4
    #define BX_LO_DLL_IMPORT __attribute__ ((visibility ("default")))
    #define BX_LO_DLL_EXPORT __attribute__ ((visibility ("default")))
    #define BX_LO_DLL_LOCAL  __attribute__ ((visibility ("hidden")))
  #else
    #define BX_LO_DLL_IMPORT
    #define BX_LO_DLL_EXPORT
    #define BX_LO_DLL_LOCAL
  #endif
#endif

#if BUILDING_LIBBX // && HAVE_VISIBILITY
  #define BX_LO_API extern BX_LO_DLL_EXPORT
#else
  #define BX_LO_API extern
#endif

typedef void * TbxLoHandle;

//--------------------------------------------
#ifdef __cplusplus
  extern "C" {
#endif
BX_LO_API int   bxVersion(char *outStr, int outLen);

//---------------------
BX_LO_API int   bxGetDeviceIdCode(TbxLoHandle h, uint32_t* p);
BX_LO_API int   bxGetStatusReg(TbxLoHandle h, uint32_t* p);
BX_LO_API int   bxGetTraceId(TbxLoHandle h, uint8_t* p);

//---------------------
BX_LO_API int   bxOpen(TbxLoHandle h);
BX_LO_API void  bxClose(TbxLoHandle h);
BX_LO_API int   bxIsOpen(TbxLoHandle h);
BX_LO_API int   bxRescan(TbxLoHandle h);

BX_LO_API int   bxSerialNumber(TbxLoHandle h, char* str, int maxLen);
BX_LO_API void  bxreadQclear(TbxLoHandle h);
BX_LO_API int   bxToggleRST(TbxLoHandle h);

//---------------------
BX_LO_API void  bxConfigInit(TbxLoHandle h, int numPages);
BX_LO_API void  bxConfigSubmitPage(TbxLoHandle h, uint8_t *p);
BX_LO_API int   bxConfigIsNeeded(TbxLoHandle h);

BX_LO_API int   bxConfigHead(TbxLoHandle h);
BX_LO_API int   bxConfigPage(TbxLoHandle h, int ix);
BX_LO_API int   bxConfigTail(TbxLoHandle h);

//---------------------
BX_LO_API int   bxAppRead(TbxLoHandle h, uint8_t *p, int AnumBytes);
BX_LO_API int   bxAppWrite(TbxLoHandle h, uint8_t *p, int AnumBytes);

BX_LO_API int   bxAppReadReg(TbxLoHandle h, int AregNum, uint8_t *pBuf, size_t aCount);
//8_LO_API int   bxAppReadReg(TbxLoHandle h, uint8_t *pBuf, size_t Acount);

BX_LO_API void  bxta(TbxLoHandle h, int x);
BX_LO_API void  bxtd(TbxLoHandle h, int x);
BX_LO_API void  bxtt(TbxLoHandle h, int x);
BX_LO_API void  bxth(TbxLoHandle h, int x);
BX_LO_API int   bxAppFlush(TbxLoHandle h);

//---------------------
BX_LO_API TbxLoHandle bxLoInit(void);
BX_LO_API void bxLoFinish(TbxLoHandle h);

#ifdef __cplusplus
  }
#endif

#endif
// EOF ----------------------------------------------------------------
/*
*/
