// libbx.cpp ---------------------------------------------------------
//
// Copyright (c) 2001 to 2014  te
//
// a C wrapper for the bx low-level code
//
// Licence:     see the LICENSE.txt file
//---------------------------------------------------------------------
#if defined(_WIN32)
  #define _CRT_SECURE_NO_WARNINGS   // Disable deprecation warning in VS2005
#else
  #define _XOPEN_SOURCE 600         // For PATH_MAX on linux
#endif

#include <string.h>

#include "libbx.h"
#include "bx.h"

#define pBxLo ((TbxLo *)h)

//---------------------------------------------------------------------
int bxVersion(char *outStr, int outLen) {
  if (outLen<=0)
    return 0;
  const char * retval = (const char *)("libbx," __DATE__ "," __TIME__);
  int retlen = strlen(retval);
  strncpy(outStr, retval, outLen);
  outStr[outLen-1] = 0;
  return retlen;
  }

int bxGetDeviceIdCode(TbxLoHandle h, uint32_t* v) {
  return pBxLo->getDeviceIdCode(*v);
  }
int bxGetStatusReg(TbxLoHandle h, uint32_t* v) {
  bool res = pBxLo->getStatusReg(*v);
  return res;
  }
int bxGetTraceId(TbxLoHandle h, uint8_t* p) {
  bool res = pBxLo->getTraceId(*(uint32_t *)p);
  return res;
  }
//---------------------
int bxOpen(TbxLoHandle h) {
  return pBxLo->open() ? 1 : 0;
  }
void bxClose(TbxLoHandle h) {
  pBxLo->close();
  }
int bxIsOpen(TbxLoHandle h) {
  return pBxLo->isOpen() ? 1 : 0;
  }
int bxRescan(TbxLoHandle h) {
  return pBxLo->rescan() ? 1 : 0;
  }
int bxSerialNumber(TbxLoHandle h, char* str, int maxLen) {
  std::string s = pBxLo->serialNumber();
  strncpy(str, s.c_str(), maxLen);
  str[maxLen-1] = 0;
  return s.size();
  }
void bxReadQclear(TbxLoHandle h) {
  pBxLo->readQclear();
  }
int bxToggleRST(TbxLoHandle h) {
  return pBxLo->toggleRST() ? 1 : 0;
  }

//---------------------
void bxConfigInit(TbxLoHandle h, int n) {
  pBxLo->configInit((unsigned)n);
  }
void bxConfigSubmitPage(TbxLoHandle h, uint8_t *p) {
  pBxLo->configSubmitPage(p);
  }
int bxConfigIsNeeded(TbxLoHandle h) {
  return pBxLo->configIsNeeded() ? 1 : 0;
  }
//---------------------
int bxConfigHead(TbxLoHandle h) {
  return pBxLo->configHead() ? 1 : 0;
  }
int bxConfigPage(TbxLoHandle h, int n) {
  return pBxLo->configPage((unsigned)n) ? 1 : 0;
  }
int bxConfigTail(TbxLoHandle h) {
  return pBxLo->configTail() ? 1 : 0;
  }
//---------------------
int bxAppRead(TbxLoHandle h, uint8_t *p, int AnumBytes) {
  return pBxLo->appRead(p, AnumBytes) ? 1 : 0;
  }
int bxAppWrite(TbxLoHandle h, uint8_t *p, int AnumBytes) {
  return pBxLo->appWrite(p, AnumBytes) ? 1 : 0;
  }
int bxAppReadReg(TbxLoHandle h, int AregNum, uint8_t *pBuf, size_t aCount) {
  return pBxLo->appReadReg(AregNum, pBuf, aCount) ? 1 : 0;
  }
//int bxAppReadReg(TbxLoHandle h, uint8_t *pBuf, size_t Acount) {
//  return pBxLo->appReadReg(pBuf, aCount);
//  }
int  bxAppFlush(TbxLoHandle h) {
  return pBxLo->appFlush() ? 1 : 0;
  }
void bxta(TbxLoHandle h, int x) { pBxLo->ta(x); }
void bxtd(TbxLoHandle h, int x) { pBxLo->td(x); }
void bxtt(TbxLoHandle h, int x) { pBxLo->tt(x); }
void bxth(TbxLoHandle h, int x) { pBxLo->th(x); }

//---------------------
TbxLoHandle bxLoInit(void) {
  return (TbxLoHandle)(new TbxLo());
  }
void bxLoFinish(TbxLoHandle h) {
  delete pBxLo;
  }

// EOF ----------------------------------------------------------------
/*
*/
