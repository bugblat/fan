// bx.cpp ------------------------------------------------------------
//
// Copyright (c) 2001 to 2014  te
//
// Licence:     see the LICENSE.txt file
//---------------------------------------------------------------------

/*
XO2 Programming Interface

-----------------------------------------------------------------------------
UFM (Sector 1) Commands
-----------------------------------------------------------------------------

 Read Status Reg        0x3C  Read the 4-byte Configuration Status Register

 Check Busy Flag        0xF0  Read the Configuration Busy Flag status

 Bypass                 0xFF  Null operation.

 Enable Config I'face   0x74  Enable Transparent UFM access - All user I/Os
 (Transparent Mode)           (except the hardened user SPI port) are governed
                              by the user logic, the device remains in User
                              mode. (The subsequent commands in this table
                              require the interface to be enabled.)

 Enable Config I'face   0xC6  Enable Offline UFM access - All user I/Os
 (Offline Mode)               (except persisted sysCONFIG ports) are tri-stated
                              User logic ceases to function, UFM remains
                              accessible, and the device enters 'Offline'
                              access mode. (The subsequent commands in this
                              table require the interface to be enabled.)

 Disable Config I'face  0x26  Disable the configuration (UFM) access.

 Set Address            0xB4  Set the UFM sector 14-bit Address Register

 Init UFM Address       0x47  Reset to the Address Register to point to the
                              first UFM page (sector 1, page 0).

 Read UFM               0xCA  Read the UFM data. Operand specifies number
                              pages to read and number of dummy bytes to
                              prepend. Address Register is post-incremented.

 Erase UFM              0xCB  Erase the UFM sector only.

 Program UFM            0xC9  Write one page of data to the UFM. Address
                              Register is post-incremented.

-----------------------------------------------------------------------------
Config Flash (Sector 0) Commands
-----------------------------------------------------------------------------

 Read Device ID code    0xE0  Read the 4-byte Device ID (0x01 2b 20 43)

 Read USERCODE          0xC0  Read 32-bit USERCODE

 Read Status Reg        0x3C  Read the 4-byte Configuration Status Register

 Check Busy Flag        0xF0  Read the Configuration Busy Flag status

 Refresh                0x79  Launch boot sequence (same as toggling PROGRAMN)

 Flash Check            0x7D  This reads the on-chip config Flash bitstream
                              and checks the CRC of the Flash bits, without
                              actually writing the bits to the configuration
                              SRAM. (This is done in the background during
                              normal device operation). Query the Flash Check
                              Status bits of the Status register for result.

 Bypass                 0xFF  Null operation.

 Enable Config I'face   0x74  Enable Transparent Configuration Flash access -
 (Transparent Mode)           All user I/Os (except the hardened user SPI port)
                              are governed by the user logic, the device
                              remains in User mode. (The subsequent commands
                              in this table require the interface to be
                              enabled.)

 Enable Config I'face   0xC6  Enable Offline Configuration Flash access -
 (Offline Mode)               All user I/Os (except persisted sysCONFIG ports)
                              are tri-stated. User logic ceases to function,
                              UFM remains accessible, and the device enters
                              ‘Offline’ access mode. (The subsequent commands
                              in this table require the interface to be
                              enabled.)

 Disable Config I'face  0x26  Exit access mode.

 Set Address            0xB4  Set the 14-bit Address Register

 Verify Device ID       0xE2  Verify device ID with 32-bit input, set Fail
                              flag if mismatched.

 Init CFG Address       0x46  Reset to the Address Register to point to the
                              first Config flash page (sector 0, page 0).

 Read Config Flash      0x73  Read the Config Flash data. Operand specifies
                              number pages to read and number of dummy bytes
                              to prepend. Address Register is post-incremented.

 Erase Flash            0x0E  Erase the Config Flash, Done bit, Security bits
                              and USERCODE

 Program Config Flash   0x70  Write 1 page of data to the Config Flash.
                              Address Register is post-incremented.

 Program DONE           0x5E  Program the Done bit

 Program SECURITY       0xCE  Program the Security bit (Secures CFG Flash
                              sector)

 Program SECURITY PLUS  0xCF  Program the Security Plus bit
                              (Secures UFM Sector)
                              (only valid when Security bit is also set)

 Program USERCODE       0xC2  Program 32-bit USERCODE

-----------------------------------------------------------------------------
Non-Volatile Register (NVR) Commands
-----------------------------------------------------------------------------

 Read Trace ID code     0x19  Read 64-bit TraceID.
-----------------------------------------------------------------------------
*/

#define _CRT_SECURE_NO_WARNINGS       /* must be before stdio, etc */

#define _DEBUG_X

#include <assert.h>
#include <time.h>

#if defined _WIN32
  #include <windows.h>
#endif

#include "ftd2xx.h"
#include "bx.h"
#include "bxtrace.h"

using namespace std;
using namespace glob;

#define XON_CHAR                0x11                /* DC1 */
#define XOFF_CHAR               0x13                /* DC3 */

#define ISC_ERASE               0x0e
#define ISC_DISABLE             0x26
#define LSC_INIT_ADDRESS        0x46
#define ISC_INIT_UFM_ADDR       0x47
#define ISC_PROG_DONE           0x5e
#define LSC_PROG_INCR_NV        0x70
#define ISC_READ_CFG_INCR       0x73
#define ISC_ENABLE_X            0x74
#define LSC_REFRESH             0x79
#define ISC_ENABLE_PROG         0xc6
#define ISC_PROG_UFM_INCR       0xc9
#define ISC_READ_UFM_INCR       0xca
#define ISC_ERASE_UFM           0xcb
#define LSC_WRITE_ADDRESS       0xb4
#define LSC_PROG_FEATURE        0xe4

#define BYPASS                  0xff
#define LSC_CHECK_BUSY          0xf0

#define IDCODE_PUB              0xe0
#define LSC_READ_STATUS         0x3c
#define READ_TRACE_ID_CODE      0x19

#define USERCODE                0xc0
#define ISC_PROGRAM_USERCODE    0xc2

#define LSC_READ_FEABITS        0xfb
#define LSC_PROG_FEABITS        0xf8


#define CFG_PAGE_SIZE           16
#define UFM_PAGE_SIZE           16

#define SRAM_ERASE              (1 << 0)
#define FEATURE_ERASE           (1 << 1)
#define CFG_ERASE               (1 << 2)
#define UFM_ERASE               (1 << 3)

#define READ_SLEEP_MILLISECS    15
#define MAX_READ_LOOP           20
#define MAX_READ_BYTES          512

// milliseconds. 1000 is definitely too small under WindowsXP.
#define USB_READ_TIMEOUT        5000
#define USB_WRITE_TIMEOUT       5000

// bytes used in the FT230 EE memory. Max is 1884 bytes.
#define FT230_EE_BYTES_USED     256

//---------------------------------------------
namespace {
  #ifdef _DEBUG_TRACE
    #include <stdio.h>
    FILE * jtagFile = 0;
    int jdump(const char *FormatStr,...) {
      int count=0;
      #define PRINT_BUFF_SIZE 256
      char PrintBuff[PRINT_BUFF_SIZE];
      va_list argptr;
      va_start(argptr, FormatStr);
      count = vsprintf(PrintBuff, FormatStr, argptr);
      PrintBuff[count] = 0;
      va_end(argptr);
      if (jtagFile == 0)
        jtagFile = fopen("bxjtag.txt", "at");
      if (jtagFile) {
        fprintf(jtagFile, PrintBuff);
        fclose(jtagFile);
        jtagFile = 0;
        }
//    OutputDebugString(PrintBuff);
      return count;
      }
  #else
    void jdump(...) {}
  #endif

  #ifdef _DEBUG_X
    #include <stdio.h>
    int jdumpx(const char *FormatStr,...) {
      int count=0;
      #define PRINT_BUFF_SIZE 256
      char PrintBuff[PRINT_BUFF_SIZE];
      va_list argptr;
      va_start(argptr, FormatStr);
      count = vsprintf(PrintBuff, FormatStr, argptr);
      PrintBuff[count] = 0;
      va_end(argptr);
      OutputDebugStringA(PrintBuff);
      return count;
      }
  #else
    void jdump(...) {}
  #endif

  const int ASYNC_BITBANG_MODE  = 1;
  const int SYNC_BITBANG_MODE   = 4;
  const int CBUS_BITBANG_MODE   = 0x20;

  const int TX_BIT              = 0;    // from FT230
  const int RX_BIT              = 1;    // to FT230
  const int RTS_BIT             = 2;    // from FT230
  const int CTS_BIT             = 3;    // to FT230

  const int TMS_BIT             = TX_BIT;
  const int TDO_BIT             = CTS_BIT;
  const int TDI_BIT             = RX_BIT;
  const int TCK_BIT             = RTS_BIT;

  const int TX_VAL              = 1 << TX_BIT;
  const int RX_VAL              = 1 << RX_BIT;
  const int RTS_VAL             = 1 << RTS_BIT;
  const int CTS_VAL             = 1 << CTS_BIT;

  const int TMS_VAL             = 1 << TMS_BIT;
  const int TDO_VAL             = 1 << TDO_BIT;
  const int TDI_VAL             = 1 << TDI_BIT;
  const int TCK_VAL             = 1 << TCK_BIT;

  const int JTAG_OUTDIR   = TMS_VAL | TDI_VAL | TCK_VAL;
  const int SERIAL_OUTDIR = TX_VAL | RTS_VAL;

  //---------------------------------------------------------------------
  // CBUS bits are
  //    0 - RST      0: normaloperation, 1: FPGA GSRn
  //    1 - K24
  //    2 - JTAGena  0: XO2 pins are GPIO, 1: pins are JTAG
  //    3 - SUSPn    0: effectively GSRn, 1: normal operation
  //
  // bits RST and JTAGena are GPIO, driven by CBUS_BITBANG

  const int CBUS_RST_BIT        = 0;
  const int CBUS_K24_BIT        = 1;
  const int CBUS_JTAGena_BIT    = 2;
  const int CBUS_SUSPn_BIT      = 3;

  const int CBUS_BITBANG_OUTDIR = 0xf0;   // all out

  const int MICROSEC  = 1000;             // nanosecs
  const int MILLISEC  = 1000 * MICROSEC;  // nanosecs

  const uint32_t ZERO = 0;
  };  // end anonymous namespace

#define ARRAY_LENGTH(x)         (sizeof(x)/sizeof(x[0]))

//---------------------------------------------
namespace {
  #ifdef _DEBUG
    uint64_t  totalSleep      = 0,    // debug and tuning traces
              totalLongSleep  = 0,
              total_ms        = 0,
              totalLong_ms    = 0;
    void incrementTotals(uint32_t ns) {
      totalSleep += ns;
      total_ms    = totalSleep/MILLISEC;
      if (ns > MILLISEC) {
        totalLongSleep += ns;
        totalLong_ms    = totalLongSleep/MILLISEC;
        }
      }
  #else
    void incrementTotals(uint32_t ns) {}
  #endif
  }

void TbxLo::jtagFlushAndNanoSleep(uint32_t ns) {
  bitbangBufFlush();
  if (ns > 0) {
    incrementTotals(ns);
  #if defined _WIN32
    uint32_t ms = ns/MILLISEC;
    Sleep((ms>0) ? ms : 1);
  #else
    struct timespec tim;
    tim.tv_sec = 0;
    tim.tv_nsec = (long)ns;
    nanosleep(&tim, NULL);
  #endif
    }
  }

//---------------------------------------------
FT_STATUS TbxLo::_check(int op, FT_STATUS ftStatus) {
  FlastResult = ftStatus;
  if (ftStatus == FT_OK)
    return FT_OK;
  else {
    close();
    throw TftDriverError(op, ftStatus);
    }
  }

//---------------------------------------------
unsigned TbxLo::_readQavail() {
  unsigned numAvail = 0;
  FT_STATUS f = FT_OK;
  if (ftHandle)
    f = FT_GetQueueStatus(ftHandle, (DWORD *)(&numAvail));
  return (f == FT_OK) ? numAvail : 0;               // never fail or throw
  }

//---------------------------------------------
void TbxLo::readQclear() {
  while (ftHandle!= 0) {
    if (FT_OK != FT_Purge(ftHandle, FT_PURGE_RX))
      return;
    unsigned numAvail = _readQavail();
    if (numAvail == 0)
      return;
    }
  }

//---------------------------------------------
size_t TbxLo::_read(uint8_t *pBuf, size_t aNeeded) {
  if (aNeeded == 0)
    return 0;
  memset(pBuf, 0, aNeeded);

  size_t totalRead=0;
  if (ftHandle) {
    size_t needed = aNeeded;
    unsigned maxLoop = MAX_READ_LOOP * (1+(aNeeded/1000)),
             numRead = 0;
    for (unsigned loop=0; loop<maxLoop; loop++) {
      unsigned numAvailable = _readQavail();
      if (numAvailable == 0)
        Sleep(READ_SLEEP_MILLISECS);
      else {
        unsigned numToRead = min(numAvailable, needed);
        _check(OP_FtRead, FT_Read(ftHandle, (BYTE *)pBuf, (DWORD)numToRead,
                                                          (DWORD *)&numRead));
        totalRead += numRead;
        pBuf      += numRead;
        needed    -= numRead;
        if (needed == 0)
          return totalRead;
        }
      }
    throw TftMiscException(BX_READ_ERROR);
    }
  return totalRead;
  }

//---------------------------------------------
size_t TbxLo::_write(uint8_t *pBuf, size_t aCount) {
  if (aCount == 0)
    return 0;

  DWORD numWritten = 0;
  if (ftHandle) {
    FT_STATUS ftStatus = FT_Write(ftHandle, pBuf, aCount, &numWritten);
    _check(OP_FtWrite, ftStatus);
    if (numWritten != aCount) {
      throw TftMiscException(BX_WRITE_ERROR);
      }
    }
  return numWritten;
  }

// ====================================================================
void TbxLo::ta(int x) {
  x = x % 64;
  Tr("write_a    %d    dec", x);
  tx(A_ADDR | x);
  }
void TbxLo::td(int x) {
  x = x % 64;
  Tr("write_d      %2x    hex", x);
  tx(D_ADDR | x);
  }
void TbxLo::tt(int x) {
  x = x % 64;
  Tr("write_t    %d    dec", x);
  tx(T_ADDR | x);
  }
void TbxLo::th(int x) {
  x = x % 64;
  Tr("write_h    %d    dec", x);
  tx(H_ADDR | x);
  }

//---------------------------------------------
bool TbxLo::appFlush() {
  size_t count = FwrBuf.size();
  if (count == 0)
    return true;
  try {
    setMode(MODE_APP);
    Tr("rem flush");
    size_t n = _write(FwrBuf.data(), count);
    FwrBuf.clear();
    return true;
    }
  catch( ... ) {
    }
  return false;
  }

//---------------------------------------------
bool TbxLo::appWrite(const uint8_t *pWrData, size_t AwrLen) {
  uint8_t *p = (uint8_t *)pWrData;
  for (size_t i=0; i<AwrLen; i++)
    tx(*p++);
  return appFlush();
  }

//---------------------------------------------
bool TbxLo::appRead(uint8_t *pRdBuf, size_t aNeeded) {
  try {
    setMode(MODE_APP);
    _read(pRdBuf, aNeeded);
    return true;
    }
  catch( ... ) {                              // all errors, incl STL errors
    }
  return false;
  }

//---------------------------------------------
void TbxLo::_appReadBlock(BYTE *pBuf, size_t aBlockCount) {
  assert(aBlockCount <= MAX_READ_BYTES);
  if (aBlockCount > 0) {
    th(aBlockCount/64);
    tt(aBlockCount);                          // effectively aBlockCount mod 64
    appFlush();
    _read(pBuf, aBlockCount);                 // exception thrown if not OK
    }
  }

//---------------------------------------------
bool TbxLo::appReadReg(int aRegNum, BYTE *pBuf, size_t aCount) {
  try {
    setMode(MODE_APP);
    ta(aRegNum);
    FcurrentReg = aRegNum;
    while (aCount > 0) {
      size_t num = min(aCount, MAX_READ_BYTES);
      _appReadBlock(pBuf, num);
      pBuf   += num;
      aCount -= num;
      }
    return true;
    }
  catch( ... ) {                              // all errors, incl STL errors
    }
  return false;
  }

//---------------------------------------------
bool TbxLo::appReadReg(BYTE *pBuf, size_t aCount) {
  return appReadReg(FcurrentReg, pBuf, aCount);
  }

//---------------------------------------------
void TbxLo::bitbangBufFlush() {
  size_t len = FbitbangWrBuf.size();
  if (len>0) {
    size_t n = _write(FbitbangWrBuf.data(), len);
    FbitbangWrBuf.clear();
    }
  }

//---------------------------------------------
void TbxLo::setCbusBitbangMode(int RSTval, int JtagEnableVal) {
  int v = ((RSTval & 1)        << CBUS_RST_BIT    )
        + ((JtagEnableVal & 1) << CBUS_JTAGena_BIT)
        + CBUS_BITBANG_OUTDIR;
  _check(FT_SetBitMode(ftHandle, (BYTE)v, CBUS_BITBANG_MODE));
  }

void TbxLo::setSyncBitbangMode(int outBitmask) {
  _check(FT_SetBitMode(ftHandle, outBitmask, SYNC_BITBANG_MODE));
  }

void TbxLo::setAsyncBitbangMode(int outBitmask) {
  _check(FT_SetBitMode(ftHandle, outBitmask, ASYNC_BITBANG_MODE));
  }

void TbxLo::clearBitbangMode() {
  setCbusBitbangMode();                 // set default values before mode swap
  _check(FT_SetBitMode(ftHandle, 0, 0));
  }

//---------------------------------------------
bool TbxLo::toggleRST() {
  if (ftHandle) {
    try {
      // could _setmode() here?
      setCbusBitbangMode(1, 0);               // RST ON, then OFF
      setCbusBitbangMode(0, 0);
      clearBitbangMode();
      readQclear();
      return true;
      }
    catch( ... ) {                            // never throw
      }
    }
  return false;
  }

//---------------------------------------------
#define JTAG_RESET      0
#define JTAG_IDLE       1
#define JTAG_IRPAUSE    2
#define JTAG_DRPAUSE    3
#define JTAG_SHIFTIR    4
#define JTAG_SHIFTDR    5
#define JTAG_DRCAPTURE  6
#define JTAG_UNKNOWN    7

const char *jtagName[] = {"RESET",
                          "IDLE",
                          "IRPAUSE",
                          "DRPAUSE",
                          "SHIFTIR",
                          "SHIFTDR",
                          "DRCAPTURE",
                          "UNKNOWN" };

struct tagJtagTransition {
   unsigned char  CurrentState;   /* From this state       */
   unsigned char  NextState;      /* Step to this state    */
   unsigned char  Pattern;        /* The tragetory of TMS  */
   unsigned char  Pulses;         /* The number of steps   */
  } jtagTransistions[] = {
    { JTAG_UNKNOWN,    JTAG_RESET,      0xFC, 6 },  /* Transitions from RESET */
    { JTAG_RESET,      JTAG_RESET,      0xFC, 6 },  /* Transitions from RESET */
    { JTAG_RESET,      JTAG_IDLE,       0x00, 1 },
    { JTAG_RESET,      JTAG_DRPAUSE,    0x50, 5 },
    { JTAG_RESET,      JTAG_IRPAUSE,    0x68, 6 },
    { JTAG_IDLE,       JTAG_RESET,      0xE0, 3 },  /* Transitions from IDLE */
    { JTAG_IDLE,       JTAG_DRPAUSE,    0xA0, 4 },
    { JTAG_IDLE,       JTAG_IRPAUSE,    0xD0, 5 },
    { JTAG_DRPAUSE,    JTAG_RESET,      0xF8, 5 },  /* Transitions from DRPAUSE */
    { JTAG_DRPAUSE,    JTAG_IDLE,       0xC0, 3 },
    { JTAG_DRPAUSE,    JTAG_IRPAUSE,    0xF4, 7 },
    { JTAG_DRPAUSE,    JTAG_DRPAUSE,    0xE8, 6 },  /* 06/14/06 Support POLING STATUS LOOP*/
    { JTAG_IRPAUSE,    JTAG_RESET,      0xF8, 5 },  /* Transitions from IRPAUSE */
    { JTAG_IRPAUSE,    JTAG_IDLE,       0xC0, 3 },
    { JTAG_IRPAUSE,    JTAG_DRPAUSE,    0xE8, 6 },
    { JTAG_DRPAUSE,    JTAG_SHIFTDR,    0x80, 2 },  /* Extra transitions using SHIFTDR */
    { JTAG_IRPAUSE,    JTAG_SHIFTDR,    0xE0, 5 },
    { JTAG_SHIFTDR,    JTAG_DRPAUSE,    0x80, 2 },
    { JTAG_SHIFTDR,    JTAG_IDLE,       0xC0, 3 },
    { JTAG_IRPAUSE,    JTAG_SHIFTIR,    0x80, 2 },  /* Extra transitions using SHIFTIR */
    { JTAG_SHIFTIR,    JTAG_IRPAUSE,    0x80, 2 },
    { JTAG_SHIFTIR,    JTAG_IDLE,       0xC0, 3 },
    { JTAG_DRPAUSE,    JTAG_DRCAPTURE,  0xE0, 4 }, /* 11/15/05 Support DRCAPTURE*/
    { JTAG_DRCAPTURE,  JTAG_DRPAUSE,    0x80, 2 },
    { JTAG_IDLE,       JTAG_DRCAPTURE,  0x80, 2 },
    { JTAG_IRPAUSE,    JTAG_DRCAPTURE,  0xE0, 4 }
    };

//---------------------------------------------
int TbxLo::setMode(int newMode) {
  int oldMode = Fmode;
  if (newMode != Fmode) {
    switch (newMode) {
      case MODE_APP :
        if (ftHandle) {
          clearBitbangMode();                   // RSTn OFF,  JTAG enable OFF
          readQclear();
          }
        FwrBuf.clear();
        break;
      case MODE_JTAG:
        FbitbangWrBuf.clear();
        FjtagClockCount = 0;
        FjtagVal = 0;
        if (ftHandle) {
          setCbusBitbangMode(0, 1);             // RSTn ON,  JTAG enable ON
          setSyncBitbangMode(JTAG_OUTDIR);
          }
        FjtagState = JTAG_UNKNOWN;
        _jtagMoveTo(JTAG_RESET);
        _jtagMoveTo(JTAG_IDLE);
        break;
      }
    Fmode = newMode;
    }
  return oldMode;
  }

//---------------------------------------------
// all JTAG ops start here
int TbxLo::_jtagVal(int tms, int tdi) {
  FjtagVal = tms*TMS_VAL + tdi*TDI_VAL;
  FbitbangWrBuf.push_back(FjtagVal            );
  FbitbangWrBuf.push_back(FjtagVal | TCK_VAL  );
  FbitbangWrBuf.push_back(FjtagVal            );

  jdump("\nTMS=%d   TDI=%d", tms, tdi);
  return FjtagVal;
  }

//---------------------------------------------
void TbxLo::_jtagMoveTo(int aState) {
  if (aState == FjtagState)
    return;
  int pattern = jtagTransistions[0].Pattern;
  int nPulses = jtagTransistions[0].Pulses;

  for (unsigned ix = 0; ix<ARRAY_LENGTH(jtagTransistions); ix++) {
    tagJtagTransition& t = jtagTransistions[ix];
    if ((t.CurrentState == FjtagState) && (t.NextState==aState)) {
      pattern = t.Pattern;
      nPulses = t.Pulses;
      break;
      }
    assert(ix != ARRAY_LENGTH(jtagTransistions)); // unknown transition
    }

  for (int i=7; i>(7-nPulses); i--) {
    int tms = (pattern >> i) & 1;
    int tdi = 0;
    _jtagVal(tms, tdi);
    }
  FjtagState = aState;

  jdump("\nstate=%s\n", jtagName[FjtagState]);
  }

//---------------------------------------------
// transitions copied from Lattice code
void TbxLo::_jtagSIR(int aOpCode, int len) {
  jdump("\n=================================");
  jdump("\nsending %2x", aOpCode);

  _jtagMoveTo(JTAG_IRPAUSE);
  _jtagMoveTo(JTAG_SHIFTIR);
  int tdi;
  for (int i=0; i<len; i++) {
    tdi = (aOpCode >> i) & 1;
    int tms = (i == (len-1)) ? 1 : 0;     // last shift to exitIR
    _jtagVal(tms, tdi);
    }
  _jtagVal(0, tdi);                        // to pauseIR
  bitbangBufFlush();
  FjtagState = JTAG_IRPAUSE;

  jdump("\n=================================\n");
  }

//---------------------------------------------
void TbxLo::_jtagSDR(uint32_t* pTdoVal, const uint32_t* pTdiVal, int len) {
  jdump("\n=================================");
  jdump("\nsetting/getting %d bits", len);

  _jtagMoveTo(JTAG_DRPAUSE);
  _jtagMoveTo(JTAG_SHIFTDR);

  if (pTdoVal) {
    jtagFlushAndNanoSleep(5 * 10 * MILLISEC); // TODO - must be a better way!
    readQclear();
    unsigned numAvailable = _readQavail();
    //printf("\nna = %d", numAvailable);
    }

  const uint32_t* pIn = pTdiVal;
  for (int i=0; i<len; i++) {
    int bitNum = i % 32;

    int tms = (i == (len-1)) ? 1 : 0;         // last shift to exitDR
    int tdi = (*pIn >> bitNum) & 1;
    _jtagVal(tms, tdi);

    if (bitNum == 31)
      pIn++;
    }

  _jtagVal(0, 0);                             // to pauseDR
  FjtagState = JTAG_DRPAUSE;
  bitbangBufFlush();

  if (pTdoVal) {
    uint32_t* pOut = pTdoVal;
    for (int i=0; i<len; i++) {
      int bitNum = i % 32;
      if (bitNum==0)
        *pOut = 0;

      BYTE buf[3] = {0,0,0};
      _read(buf, 3);
      uint32_t tdo = (buf[0] >> TDO_BIT) & 1;
      *pOut |= tdo << bitNum;

      if (bitNum == 31)
        pOut++;
      }
    }
  jdump("\n=================================\n");
  }

//---------------------------------------------
int TbxLo::_jtagBusyBit() {
  uint32_t vrd = 0;
  _jtagSDR(&vrd, &ZERO, 1);
  return (vrd & 1);
  }

//---------------------------------------------
// anonymous variables for inspection during debug
namespace {
  int vnbCounter = -1;
  int wnbCounter = -1;
  }

//---------------------------------------------
bool TbxLo::_jtagWaitForNotBusy(int tclks, uint32_t dly, int maxLoops) {
  _jtagSIR(LSC_CHECK_BUSY);
  for (wnbCounter=0; wnbCounter<maxLoops; wnbCounter++) {
    _jtagRuntest(tclks, dly);
    if (_jtagBusyBit() == 0)
      return true;
    }
  return false;
  }

//---------------------------------------------
bool TbxLo::_jtagVerifyNotBusy() {
  _jtagSIR(LSC_CHECK_BUSY);
  _jtagMoveTo(JTAG_IDLE);
  for (vnbCounter=0; vnbCounter<MAX_BUSY_LOOPS; vnbCounter++) {
    if (_jtagBusyBit() == 0)
      return true;
    _jtagRuntest(0, BUSY_LOOP_DELAY);
    }
  return false;
  }

//---------------------------------------------
// tecnically should remain in RUNTEST/IDLE state until the later of
// tclks and dly - i.e. count them in parallel. We run them consecutively
// because we are not too concerned about total running time.
void TbxLo::_jtagRuntest(int tclks, uint32_t dly) {
  _jtagMoveTo(JTAG_IDLE);
  for (int i=0; i<tclks; i++) {
    _jtagVal(0, 0);
    }
  jtagFlushAndNanoSleep(dly);
  }

//---------------------------------------------
bool TbxLo::_getSimple(uint8_t Acmd, uint32_t& v, int len) {
  _jtagSIR(Acmd);
  v = 0;
  _jtagSDR(&v, &ZERO, len);
  return true;
  }

//---------------------------------------------
bool TbxLo::_putSimple(uint8_t Acmd, uint32_t Ap, int len) {
  _jtagVerifyNotBusy();
  _jtagSIR(Acmd);
  _jtagSDR(0, &Ap, len);
  _jtagRuntest(2);
  return true;
  }

//---------------------------------------------
void  TbxLo::dumpStatusReg() {
  uint32_t v = ~0;
  getStatusRegX(v);
  int D  = (v >>  8) & 1;
  int C  = (v >>  9) & 1;
  int B  = (v >> 12) & 1;
  int F  = (v >> 13) & 1;
  int E  = (v >> 23) & 7;
  jdumpx("\nSR:0x%08x  Done:%d  Cfg:%d  Busy:%d  Fail:%d  Err:%d  ", v,D,C,B,F,E);
  }

//---------------------------------------------
void TbxLo::refresh() {
  _jtagVerifyNotBusy();
  _jtagSIR(LSC_REFRESH);
  _jtagRuntest(2, 1000 * MILLISEC);
  _jtagSIR(BYPASS);                             // from SVF, BYPASS seems to be needed
  _jtagRuntest(100, 100 * MILLISEC);
  }

//---------------------------------------------
bool TbxLo::programDoneBit() {
  bool ok = _putSimple(ISC_PROG_DONE);
  _jtagRuntest(2, 10 * MILLISEC);
  _jtagSIR(BYPASS);                             // from SVF, BYPASS seems to be needed
  _jtagRuntest(2, 1 * MILLISEC);
  return ok;
  }

//---------------------------------------------
bool TbxLo::erase(int Amask) {
  bool ok = _putSimple(ISC_ERASE, Amask);
  _jtagRuntest(2);
  _jtagWaitForNotBusy(2, (10 * MILLISEC), 310);   // up to 3.1 secs!
  _jtagVerifyNotBusy();
  return ok;
  }

//---------------------------------------------
bool TbxLo::eraseCfg()  { return erase(CFG_ERASE); }
bool TbxLo::eraseAll()  { return erase(UFM_ERASE | CFG_ERASE | FEATURE_ERASE); }

bool TbxLo::eraseUfm() {
  bool ok = _putSimple(ISC_ERASE_UFM);
  _jtagRuntest(2);
  _jtagVerifyNotBusy();
  return ok;
  }

//---------------------------------------------
bool TbxLo::initCfgAddr(uint32_t param) {        // TODO not in docs
  bool ok = _putSimple(LSC_INIT_ADDRESS, param);
  _jtagRuntest(2, (10 * MILLISEC));
  return ok;
  }

//---------------------------------------------
bool TbxLo::_initUfmAddr() {
  bool ok = _putSimple(ISC_INIT_UFM_ADDR);
  jtagFlushAndNanoSleep(10 * MILLISEC);
  return ok;
  }

//---------------------------------------------
bool TbxLo::_setUfmPageAddr(int pageNumber) {
  uint32_t v = (uint32_t)(0x40000000 | (pageNumber & 0x3fff));
  _jtagSIR(LSC_WRITE_ADDRESS);
  _jtagSDR(0, &v, 32);
  _jtagRuntest(2);
  _jtagVerifyNotBusy();
  return true;
  }

//---------------------------------------------
/*
! Shift in LSC_PROG_INCR_NV(0x70) instruction
SIR 8 TDI  (70);
! Shift in Data Row = 1
SDR 128 TDI  (115100000040000000DCFFFFCDBDFFFF);
RUNTEST IDLE  2 TCK;
! Shift in LSC_CHECK_BUSY(0xF0) instruction
SIR 8 TDI  (F0);
LOOP 10 ;
RUNTEST IDLE  1.00E-003 SEC;
SDR 1 TDI  (0)
    TDO  (0);
ENDLOOP ;
*/

bool TbxLo::_progPage(int Acmd, const uint8_t *p) {
  _jtagSIR(Acmd);
  _jtagSDR(0, (uint32_t *)p, 16*8);             // relies on little-endian!
  _jtagRuntest(2);
  _jtagVerifyNotBusy();
  return true;
  }

//---------------------------------------------
bool TbxLo::_readPage(int Acmd, uint8_t *p) {
  const uint32_t totalPages     = 1;
  const uint32_t numBytesToRead = CFG_PAGE_SIZE * totalPages;

  _jtagSDR(0, &numBytesToRead, 24);             // TODO before inst?
  _jtagSIR(Acmd);
  const uint32_t zeroArray[] = {0,0,0,0};
  _jtagSDR((uint32_t *)p, zeroArray, 16*8);     // relies on little-endian!
  return true;
  }

//---------------------------------------------
bool TbxLo::_readPages(int Acmd, int numPages, uint8_t *p) {
  assert((numPages >= 0) && (p != 0));
  bool ok = true;
  for (int i=0; ok && (i<numPages); i++) {
    ok = _readPage(Acmd, p + CFG_PAGE_SIZE*i);
    }
  return ok;
  }

//---------------------------------------------
bool TbxLo::progCfgPage(const uint8_t *p) {
  return _progPage(LSC_PROG_INCR_NV, p);
  }

bool TbxLo::readCfgPages(int numPages, uint8_t *p) {
  return _readPages(ISC_READ_CFG_INCR, numPages, p);
  }

bool TbxLo::_progUfmPage(const uint8_t *p) {
  return _progPage(ISC_PROG_UFM_INCR, p);
  }

bool TbxLo::readUfmPages(int numPages, uint8_t *p) {
  return _readPages(ISC_READ_UFM_INCR, numPages, p);
  }

bool TbxLo::readUfmPages(int pageNumber, int numPages, uint8_t *p) {
  bool ok = enableCfgInterface();

  ok = _setUfmPageAddr(pageNumber);
  ok = readUfmPages(numPages, p);

  _jtagVerifyNotBusy();
  ok = programDoneBit();
  ok = disableCfgInterface();
  return ok;
  }

bool TbxLo::writeUfmPages(int pageNumber, int numPages, uint8_t *p) {
  bool ok = enableCfgInterface();

  ok = _setUfmPageAddr(pageNumber);
  for (int i=0; i<numPages; i++)
    ok = _progUfmPage(p + UFM_PAGE_SIZE*i);

  _jtagVerifyNotBusy();
  ok = programDoneBit();
  ok = disableCfgInterface();
  return ok;
  }

//---------------------------------------------
bool TbxLo::getUsercodes(uint32_t* pv) {
  uint32_t FLASHcode=0x99, SRAMcode=0x33;
  enableCfgInterface();
  _getSimple(USERCODE, FLASHcode, 32);
  disableCfgInterface();
  _getSimple(USERCODE, SRAMcode, 32);
  pv[0] = FLASHcode;
  pv[1] = SRAMcode;
  return true;
  }

bool TbxLo::setUsercode(uint32_t v) {
//enableCfgInterface();
  _jtagSIR(USERCODE);
  _jtagSDR(0, &v, 32);
  _jtagSIR(ISC_PROGRAM_USERCODE);
  _jtagRuntest(2, (10 * MILLISEC));
  _jtagVerifyNotBusy();
  return true;
  }

//---------------------------------------------
bool TbxLo::getFEAbitsInCfg(uint32_t& v) {
  _jtagSIR(LSC_READ_FEABITS);
  v = 0;
  _jtagRuntest(2, (100 * MILLISEC));
  _jtagSDR(&v, &ZERO, 16);
  return true;
  }

bool TbxLo::getFEAbits(uint32_t& v) {
  enableCfgInterface();
  getFEAbitsInCfg(v);
  disableCfgInterface();
  return true;
  }

bool TbxLo::setFEAbits(uint32_t v) {
/*_jtagSIR(ISC_INIT_CFG_ADDR);
  uint32_t voldad = 0, vaddr = 2;
  _jtagSDR(&voldad, &vaddr, 8);           // from SVF. Why??
  _jtagRuntest(2, (10 * MILLISEC));
  _jtagVerifyNotBusy();                */

  _jtagSIR(LSC_PROG_FEABITS);
  _jtagSDR(0, &v, 16);
  _jtagRuntest(2);
  _jtagVerifyNotBusy();
  return true;
  }

//---------------------------------------------
bool TbxLo::enableCfgInterfaceOffline(uint32_t param) {
  bool ok = _putSimple(ISC_ENABLE_PROG, param);
  _jtagRuntest(2, (10 * MILLISEC));       // from SVF
  _jtagVerifyNotBusy();
  return ok;
  }

//---------------------------------------------
bool TbxLo::enableCfgInterfaceTransparent() {
  bool ok = _putSimple(ISC_ENABLE_X, 0x08);
  _jtagRuntest(2, 10 * MILLISEC);         // from SVF
  _jtagVerifyNotBusy();
  return ok;
  }

//---------------------------------------------
bool TbxLo::disableCfgInterface() {
  _jtagSIR(ISC_DISABLE);
  _jtagRuntest(2, 1000 * MILLISEC);       // from SVF
  _jtagSIR(BYPASS);
  _jtagRuntest(2, 100 * MILLISEC);
  return true;
  }

//---------------------------------------------
void TbxLo::getDeviceIdCodeX(uint32_t& v) {
  _getSimple(IDCODE_PUB, v, 32);
  }

//---------------------------------------------
void TbxLo::getStatusRegX(uint32_t& v) {
  v = 0;
  _jtagSIR(LSC_READ_STATUS);
  _jtagRuntest(2, 1 * MILLISEC);
  _jtagSDR(&v, &ZERO, 32);
  }

//---------------------------------------------
void TbxLo::getTraceIdX(uint32_t& v0) {
  _getSimple(READ_TRACE_ID_CODE, v0, 64);
  }




// public functions ===================================================
// all are try/catch guarded
bool TbxLo::getDeviceIdCode(uint32_t& v) {
  try {
    v = 0;
    setMode(MODE_JTAG);
    getDeviceIdCodeX(v);
    setMode(MODE_APP);
    return true;
    }
  catch(...) { return false; }
  }

//---------------------------------------------
bool TbxLo::getStatusReg(uint32_t& v) {
  try {
    v = 0;
    setMode(MODE_JTAG);
    getStatusRegX(v);
    setMode(MODE_APP);
    return true;
    }
  catch(...) { return false; }
  }

//---------------------------------------------
bool TbxLo::getTraceId(uint32_t& v0) {
  try {
    v0 = 0;
    setMode(MODE_JTAG);
    getTraceIdX(v0);
    setMode(MODE_APP);
    return true;
    }
  catch(...) { return false; }
  }

//---------------------------------------------
bool TbxLo::startsWith(const string& bigString, const string& smallString) {
  return (0 == bigString.compare(0, smallString.length(), smallString));
  }

//---------------------------------------------
bool TbxLo::open() {
  if (ftHandle) {                             // already open
    readQclear();
    return true;
    }

  char  SerialStr[64], Description[64];
  DWORD DevCount = 0;
  bool found = false;

  try {
    _check(FT_CreateDeviceInfoList(&DevCount));

    for (DWORD ix=0; (ix<DevCount) && !found; ix++) {
      DWORD Flags, Type, ID, LocId;

      memset(SerialStr, 0, sizeof(SerialStr));
      memset(Description, 0, sizeof(Description));
      _check(FT_GetDeviceInfoDetail(ix, &Flags, &Type, &ID, &LocId,
                            (PVOID)SerialStr, (PVOID)Description, &ftHandle));
      Fserial = SerialStr;
      string description = Description;

      bool okVidPid = (ID == FvidPid)
                        || ( (0 == FvidPid)
                               && (ID == ((VID_FT << 16) | PID_FT230)) );
      // recognise anything if vid/pid is set to 0
      bool okDescription = (0 == FvidPid)
                              || startsWith(description, "Fan")
                              || startsWith(description, "BX");
      bool okSerial      = (0 == FvidPid)
                              || startsWith(Fserial, "BX");

      found = okVidPid && okDescription && okSerial;
      }

    if (!found) {
      close();                          // clear vars to nulls
      return false;
      }

    _check(FT_OpenEx(SerialStr, FT_OPEN_BY_SERIAL_NUMBER, &ftHandle));
      // 0 is 3Mbit/s, 1 is 2Mbit/s, 2 is 1.5Mbit/s, 3 is 1Mbit/s
    _check(FT_SetDivisor(ftHandle, 0));
    _check(FT_SetDataCharacteristics(ftHandle, FT_BITS_8, FT_STOP_BITS_1,
                                                              FT_PARITY_NONE));
    _check(FT_SetFlowControl(ftHandle, FT_FLOW_NONE, 0, 0));
    _check(FT_SetRts(ftHandle));
    _check(FT_ClrDtr(ftHandle));
    _check(FT_SetTimeouts(ftHandle, USB_READ_TIMEOUT, USB_WRITE_TIMEOUT));

    setMode(MODE_APP);
    toggleRST();                        // also clears any bitbang mode
    return true;
    }
  catch(const TftDriverError& ) {
    close();                            // clear vars to nulls
    return false;
    }
  }

//---------------------------------------------
void TbxLo::close() {
  if (ftHandle)
    FT_Close(ftHandle);                 // never fail, never throw
  ftHandle = 0;
  Fserial.clear();
  Fmode = MODE_UNDEFINED;
  }

//============================================
// FT230 on-board memory routines
void TbxLo::FTmemRead(vector< vector<uint8_t> >& items) {
  DWORD BytesRead = 0;
  uint8_t buf[FT230_EE_BYTES_USED];

  memset(buf, 0, sizeof(buf));
  items.clear();

  // very slow!
  if (FT_EE_UARead (ftHandle, buf, sizeof(buf), &BytesRead) != FT_OK)
    return;

  unsigned a = 0;
  while (a < sizeof(buf)) {
    if (buf[a] == 0)                            // empty/last entry
      break;
    unsigned len = buf[a];
    if (len < 2)                                // illegal length
      break;
    if ((a + len) > sizeof(buf))                // off the end
      break;
    vector<uint8_t> item;
    item.resize(len);
    for (unsigned i=0; i<len; i++)
      item[i] = buf[a++];
    items.push_back(item);
    }
  }

//---------------------------------------------
void TbxLo::FTmemWrite(vector< vector<uint8_t> >& items) {
  uint8_t buf[FT230_EE_BYTES_USED];
  unsigned pos = 0;
  memset(buf, 0, sizeof(buf));

  for (unsigned ix=0; ix<items.size(); ix++) {
    vector<uint8_t>& item = items[ix];
    for (unsigned i=0; i<item.size(); i++) {
      if (pos<sizeof(buf))
        buf[pos++] = item[i];
      }
    }
  FT_EE_UAWrite(ftHandle, buf, sizeof(buf));
  }

//---------------------------------------------
void TbxLo::FTmemFixup(vector< vector<uint8_t> >& items,
                                            vector<uint8_t>& xitem) {
  unsigned len = xitem.size();
  if (len<2)
    return;
  if (len != xitem[0])
    return;
  uint8_t flag = xitem[1];

  for (unsigned ix=0; ix<items.size(); ix++) {
    vector<uint8_t>& item = items[ix];
    if (item[1] == flag) {
      item.resize(len);
      for (unsigned i=0; i<len; i++) {
        item[i] = xitem[i];
        }
      return;
      }
    }

  // not found so push onto the back
  items.push_back(xitem);
  }

//---------------------------------------------
bool TbxLo::FTmemGetCRC(uint32_t& Acrc) {
  vector< vector<uint8_t> > items;
  FTmemRead(items);

  for (unsigned ix=0; ix<items.size(); ix++) {
    vector<uint8_t>& item = items[ix];
    if ((item[0] == FPGA_CFG_CRC_LEN) && (item[1] == FPGA_CFG_CRC_FLAG)) {
      Acrc = ((uint32_t)item[2] <<  0) |
             ((uint32_t)item[3] <<  8) |
             ((uint32_t)item[4] << 16) |
             ((uint32_t)item[5] << 24);
      return true;
      }
    }

  return false;
  }

//---------------------------------------------
bool TbxLo::FTmemSetCRC(uint32_t Acrc) {
  vector< vector<uint8_t> > items;
  FTmemRead(items);

  // fixup the CRC entry
  vector<uint8_t> item;
  item.resize(FPGA_CFG_CRC_LEN);
  item[0] = FPGA_CFG_CRC_LEN;
  item[1] = FPGA_CFG_CRC_FLAG;
  for (unsigned i=0; i<4; i++) {
    item[2+i] = uint8_t(Acrc >> (8*i));
    }
  FTmemFixup(items, item);

  FTmemWrite(items);
  return true;
  }

//============================================
// config routines
void TbxLo::configInit(unsigned numPages) {
  FcfgData.clear();
  FcfgData.reserve(numPages*CFG_PAGE_SIZE);
  Fcrc = 0;
  }

//---------------------------------------------
void TbxLo::configSubmitPage(uint8_t *p) {
  for (int i=0; i<CFG_PAGE_SIZE; i++)
    FcfgData.push_back(*p++);
  }

//---------------------------------------------
uint32_t TbxLo::configSetSubmittedPagesCRC() {
  make_crc_table();
  Fcrc = calc_crc(&FcfgData[0], FcfgData.size());
  return Fcrc;
  }

//---------------------------------------------
bool TbxLo::configIsNeeded() {
  configSetSubmittedPagesCRC();
  uint32_t bxCRC = 0;
  bool ok = FTmemGetCRC(bxCRC);
  return (!ok) || (Fcrc != bxCRC);
  }

//---------------------------------------------
bool TbxLo::configHead() {
  uint32_t temp = 0;

  try {
    setMode(MODE_JTAG);
    getDeviceIdCodeX(temp);
    if (temp == ID_XO2_2000HC) {
      enableCfgInterfaceOffline(0x08);
      dumpStatusReg();
      erase(CFG_ERASE | SRAM_ERASE);
      getStatusRegX(temp);                      // TDO=0, MASK=0x00003000
      initCfgAddr(0x04);                        // program CFG
      // dumpStatusReg();
      return true;
      }
    }
  catch(...) {}
  return false;
  }

//---------------------------------------------
bool TbxLo::configPage(unsigned ix) {
  try {
    _jtagSIR(LSC_PROG_INCR_NV);
    uint32_t *p = (uint32_t *)(&FcfgData[CFG_PAGE_SIZE * ix]);
    _jtagSDR(0, p, CFG_PAGE_SIZE*8);          // relies on little-endian!

    // with a 3MHz clock and three transitions per clock,
    // this will be at least 200us, as in the spec
    // and faster than using the MS Sleep()
    _jtagRuntest(200, 0);
    _jtagSIR(LSC_CHECK_BUSY);                 // change the value in the IR
    bitbangBufFlush();                        // prevent the buffer filling up
    readQclear();
    return true;
    }
  catch(...) {}
  return false;
  }

//---------------------------------------------
bool TbxLo::configTail() {
  uint32_t tempSR = 0, tempFB = 0;
  const uint32_t FEABITS_VAL = 0x700;

  try {
    bitbangBufFlush();                  // safety first, but usually not needed
    jtagFlushAndNanoSleep(10 * MILLISEC);
    readQclear();                       // usually a few thousand junk entries

    setUsercode(0x46616e61);            // Fana
    getStatusRegX(tempSR);              // MASK (00003000);
    getFEAbitsInCfg(tempFB);
    programDoneBit();
    if (tempFB != FEABITS_VAL)
      setFEAbits(FEABITS_VAL);          // all ports disabled, use JTAG
    disableCfgInterface();
    // dumpStatusReg();
    refresh();

    setMode(MODE_APP);
    if (Fcrc != 0)
      FTmemSetCRC(Fcrc);
    return true;
    }
  catch(...) {}
  return false;
  }

void TbxLo::tmp() {
  }

// CRC stuff ==================================
/* Make the table for a fast CRC. */
void TbxLo::make_crc_table() {
  uint32_t c;
  int n, k;

  for (n = 0; n < 256; n++) {
    c = (uint32_t) n;
    for (k = 0; k < 8; k++) {
      if (c & 1)
        c = 0xedb88320L ^ (c >> 1);
      else
        c = c >> 1;
      }
    Fcrc_table[n] = c;
    }
  }

//---------------------------------------------
/* Update a running CRC with the bytes buf[0..len-1]
   The CRC should be initialized to all 1's, and the transmitted value is
     the 1's complement of the final running CRC
   See the calc_crc() routine below. */
uint32_t TbxLo::update_crc(uint32_t Acrc, uint8_t *buf, int len) {
  uint32_t c = Acrc;
  int n;

  for (n = 0; n < len; n++) {
    c = Fcrc_table[(c ^ buf[n]) & 0xff] ^ (c >> 8);
    }
  return c;
  }

//---------------------------------------------
// Return the CRC of the bytes buf[0..len-1].
uint32_t TbxLo::calc_crc(uint8_t *buf, int len) {
  return update_crc(0xffffffffL, buf, len) ^ 0xffffffffL;
  }

//=============================================
TbxLo::TbxLo(unsigned Avid, unsigned Apid) {
  ftHandle = 0;
  FvidPid = (Avid << 16) | Apid;
  FcurrentReg = 0;
  FjtagVal = 0;
  FjtagClockCount = 0;
  Fmode = MODE_UNDEFINED;
  open();                               // try to open, may fail
  }

//---------------------------------------------
TbxLo::~TbxLo() { close(); }

// EOF ----------------------------------------------------------------
