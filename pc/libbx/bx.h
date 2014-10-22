// bx.h -------------------------------------------------------------
//
// Copyright (c) 2001 to 2014  te
//
// Licence:     see the LICENSE.txt file
//---------------------------------------------------------------------
#ifndef bxH
#define bxH

#include <stdint.h>
#include <vector>
#include <string>
#include "libbx.h"

#ifndef BASETYPES
  #define BASETYPES
  typedef unsigned long     ULONG;
  typedef ULONG            *PULONG;
  typedef unsigned short    USHORT;
  typedef USHORT           *PUSHORT;
  typedef unsigned char     UCHAR;
  typedef UCHAR            *PUCHAR;
  typedef char             *PSZ;
#endif  /* !BASETYPES */

// retro typedefs for the FTDI interface
typedef void               *PVOID;
typedef PVOID               FT_HANDLE;
typedef ULONG               FT_STATUS;
typedef unsigned long       DWORD;

#define BUSY_LOOP_DELAY     1                         // millisecs
#define MAX_BUSY_LOOPS      (100/BUSY_LOOP_DELAY)

// data stored in FT230 EEPROM
#define USB_SERIAL_FLAG     1
#define USB_SERIAL_LEN      (1+1+10)
#define FPGA_CFG_CRC_FLAG   2
#define FPGA_CFG_CRC_LEN    (1+1+4)

//=====================================================================
class TftDriverError {
  public:
    DWORD Ferr;
    int FOp;
    TftDriverError(int op, DWORD err) : FOp(op), Ferr(err) {}
  };

//=====================================================================
class TftMiscException {
  public:
    int Ferr;
    TftMiscException(int err) { Ferr = err; }
  };

//=====================================================================
enum Tmode     { MODE_UNDEFINED=0, MODE_APP=1, MODE_JTAG };

class TbxLo {
  //---------------------------------------------
  private:
    void       *ftHandle;
    int         FlastResult;
    uint32_t    FvidPid;
    int         FcurrentReg,
                FjtagVal,
                FjtagClockCount,
                FjtagState,
                Fmode;

    std::string Fserial;

    std::vector<uint8_t>  FbitbangRdBuf, FbitbangWrBuf;
    std::vector<uint8_t>  FrdBuf, FwrBuf;

    std::vector<uint8_t>  FcfgData;
    uint32_t              Fcrc_table[256];
    uint32_t              Fcrc;             // CRC of the config data

    void jtagFlushAndNanoSleep(uint32_t ns);

    bool startsWith(const std::string& bigstring,
                                        const std::string& smallstring);

    FT_STATUS _check(int op, FT_STATUS ftStatus);
    FT_STATUS _check(FT_STATUS ftStatus) { return _check(0, ftStatus); }

    unsigned _readQavail();
    size_t   _read(uint8_t *pBuf, size_t aNeeded);
    size_t   _write(uint8_t *pBuf, size_t aCount);
    void     _appReadBlock(uint8_t *pBuf, size_t aBlockCount);

    void  bitbangBufFlush();

    void  setCbusBitbangMode(int RSTval=0, int JtagEnableVal=0);   // defaults
    void  setSyncBitbangMode(int outBitmask);
    void  setAsyncBitbangMode(int outBitmask);
    void  clearBitbangMode();

    int   _jtagVal(int tms, int tdi);
    void  _jtagMoveTo(int aState);
    void  _jtagSIR(int aOpCode, int len=8);
    void  _jtagSDR(uint32_t* pOutVal, const uint32_t* pInVal, int len=32);

    int   _jtagBusyBit();
    bool  _jtagVerifyNotBusy();
    bool  _jtagWaitForNotBusy(int tclks, uint32_t dly, int maxLoops);
    void  _jtagRuntest(int tclks=2, uint32_t dly=0);

    bool  _getSimple(uint8_t Acmd, uint32_t& v, int len);
    bool  _putSimple(uint8_t Acmd, uint32_t Ap=0, int len=8);

    bool  _initUfmAddr();
    bool  _progPage(int Acmd, const uint8_t *p);
    bool  _readPages(int Acmd, int numPages, uint8_t *p);
    bool  _readPage(int Acmd, uint8_t *p);
    bool  _setUfmPageAddr(int pageNumber);
    bool  _progUfmPage(const uint8_t *p);

    //-------------------------------------------
    void  dumpStatusReg();

    bool  enableCfgInterfaceOffline(uint32_t param=0x08);          // SVF default
    bool  enableCfgInterfaceTransparent();

    bool  enableCfgInterface() { return  enableCfgInterfaceTransparent(); }
    bool  disableCfgInterface();
    void  refresh();
    bool  programDoneBit();

    bool  isBusy() { return _jtagWaitForNotBusy(0,0,1); }

    bool  erase(int Amask);
    bool  eraseAll();
    bool  eraseCfg();
    bool  eraseUfm();

    void  FTmemRead(std::vector< std::vector<uint8_t> >& items);
    void  FTmemWrite(std::vector< std::vector<uint8_t> >& items);
    void  FTmemFixup(std::vector< std::vector<uint8_t> >& items,
                                                std::vector<uint8_t>& xitem);
    bool  initCfgAddr(uint32_t param);
    bool  progCfgPage(const uint8_t *p);
    bool  readCfgPages(int numPages, uint8_t *p);

    bool  readUfmPages(int numPages, uint8_t *p);
    bool  readUfmPages(int pageNumber, int numPages, uint8_t *p);
    bool  writeUfmPages(int pageNumber, int numPages, uint8_t *p);

    bool  setUsercode(uint32_t v);
    bool  getUsercodes(uint32_t* v);

    bool  setFEAbits(uint32_t v);
    bool  getFEAbitsInCfg(uint32_t& v);
    bool  getFEAbits(uint32_t& v);

    void  getDeviceIdCodeX(uint32_t& v);
    void  getStatusRegX(uint32_t& v);
    void  getTraceIdX(uint32_t& v0);

    void     make_crc_table();
    uint32_t update_crc(uint32_t crc, uint8_t *buf, int len);
    uint32_t calc_crc(uint8_t *buf, int len);

  //---------------------------------------------
  public:
    bool      getDeviceIdCode(uint32_t& v);
    bool      getStatusReg(uint32_t& v);
    bool      getTraceId(uint32_t& v0);

    void      readQclear();
    bool      toggleRST();

    void *    getFtHandle() { return ftHandle; }
    bool      open();
    void      close();
    bool      isOpen() { return (ftHandle != 0); }
    bool      rescan() { return isOpen() ? true : open(); }
    std::string& serialNumber() { return Fserial; }

    int       setMode(int aNewMode);

    bool      FTmemGetCRC(uint32_t& crc);
    bool      FTmemSetCRC(uint32_t crc);

    void      configInit(unsigned numPages);
    void      configSubmitPage(uint8_t *p);
    uint32_t  configSetSubmittedPagesCRC();
    bool      configIsNeeded();

    bool      configHead();
    bool      configPage(unsigned ix);
    bool      configTail();

    void      tx(int x) { FwrBuf.push_back((uint8_t)x); }

    void      ta(int x);
    void      td(int x);
    void      tt(int x);
    void      th(int x);
    bool      appFlush();

    bool      appReadReg(int AregNum, uint8_t *pBuf, size_t aCount);
    bool      appReadReg(uint8_t *pBuf, size_t Acount);

    bool      appWrite(const uint8_t *pWrData, size_t aWrLen);
    bool      appRead(uint8_t *pRdBuf, size_t aNeeded);
void tmp();
    //-------------------------------------------
    TbxLo(unsigned Avid=VID_FT, unsigned Apid=PID_FT230);
    ~TbxLo();
  };

#endif

// EOF ----------------------------------------------------------------
