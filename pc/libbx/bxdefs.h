// bxdefs.h -----------------------------------------------------------
//
// Copyright (c) 2001 to 2014  te
//
// Licence:     see the LICENSE.txt file
//---------------------------------------------------------------------
#ifndef bxdefsH
#define bxdefsH

#define NOMINMAX      /* for Visual C++ */

#if defined(Q_OS_WIN32) || defined (_WIN32) || defined(__WIN32__) || defined(__WINDOWS__) || defined (_MSC_VER)
  #define LOOKS_LIKE_WINDOWS
#endif

#include <stdint.h>

#if defined(_MSC_VER) && !(defined(_STDINT) || defined(_MSC_STDINT_H_))
  typedef signed   __int8   int8_t;
  typedef unsigned __int8   uint8_t;
  typedef signed   __int16  int16_t;
  typedef unsigned __int16  uint16_t;
  typedef signed   __int32  int32_t;
  typedef unsigned __int32  uint32_t;
  typedef signed   __int64  int64_t;
  typedef unsigned __int64  uint64_t;
#endif

#if !defined(_WINDEF_)
  typedef uint8_t     BYTE;
#endif

#define myABS(x)                    (((x)<0)?(-x):(x))
#define myMAX(a,b)                  std::max((a),(b))
#define myMIN(a,b)                  std::min((a),(b))

#define ARRAY_LENGTH(x)             (sizeof(x)/sizeof(x[0]))

//---------------------------------------------------------------------
// return codes
#define BX_OK                        0
#define BX_ERROR                     -1
#define BX_BAD_HANDLE                -2
#define BX_BAD_PARAMETER             -3
#define BX_BUFFER_TOO_SMALL          -4
#define BX_READ_ERROR                -10
#define BX_WRITE_ERROR               -11

//====================================
// register layout
#define ID_REG                        0
#define CONTROL_REG                   1
#define STATUS_REG                    2
#define PIN_STATUS_REG                3
#define CLOCK_TYPE_REG                4
#define COUNTER_TIMER_REG             5
#define MATCH_COMBINE_REG             6
#define MATCH_EVAL_REG                7
#define SM_EVAL_REG                   8
#define TRIG_OUT_REG                  9
#define RAM_ADDR_REG                  10
#define RAM_DATA_REG                  11
#define EFB_ADDR_REG                  12
#define EFB_DATA_REG                  13
#define SCRATCH_REG                   31

//------------------------------------
// main control register. RW
// CONTROL_REG
    #define CTL_RESET                 0   // Reset
    #define CTL_RUN                   1   // Run
    #define CTL_STOP                  2   // force a stop
    #define CTL_UNUSED_3              3
    #define CTL_RESETCLK              4   // reset the PLL
    #define CTL_UNUSED_5              5
    #define CTL_UNUSED_6              6
    #define CTL_CLKSRUNNING           7   // PLLs/DCM(s) locked

//------------------------------------
// main acquisition state machine status reg. RO
// STATUS_REG
  // readback Status subregisters
  //  0     Status readback 0
  //  1     Status readback 1         undefined
  //  2     Status readback 2         undefined
  //  3     Status readback 3         undefined
  //
  //  4     Trigger Point Byte 0
  //  5     Trigger Point Byte 1
  //  6     Trigger Point Byte 2      0 if unused
  //  7     Trigger Point Byte 3      0 if unused
  //
  //  8     Final Wr Address Byte 0
  //  9     Final Wr Address Byte 1
  // 10     Final Wr Address Byte 2   0 if unused
  // 11     Final Wr Address Byte 3   0 if unused
  #define STATUS_REG_NUM_SUBS         16
  //---------------------------
  // subaddress 0
    #define STATUS_REG_STATUS         0
    // bits 5..0:
      #define LAidleIX                1
      #define LAprefillIX             2
      #define LAsearchIX              3
      #define LAhit1IX                4
      #define LAhit2IX                5
      #define LAtriggeredIX           6
      #define LAdoneIX                7
      #define LAnonsense              0
    // bit 6 - set after all the RAM has been written at least once
      #define STATUS_RAMWRITTEN       6
    // bit 7 - set after the analyser has triggered
      #define STATUS_TRIGGERED        7
  //---------------------------
  // subaddresses 4..7
  // trigger point readout
    #define STATUS_REG_TRIG_BYTE_0    4
    #define STATUS_REG_TRIG_BYTE_1    5
    #define STATUS_REG_TRIG_BYTE_2    6
    #define STATUS_REG_TRIG_BYTE_3    7
  //---------------------------
  // subaddresses 8..11
  // final RAM write address readout
    #define STATUS_REG_RAMA_BYTE_0    8
    #define STATUS_REG_RAMA_BYTE_1    9
    #define STATUS_REG_RAMA_BYTE_2    10
    #define STATUS_REG_RAMA_BYTE_3    11

//------------------------------------
// pin status readout RO
// PIN_STATUS_REG
  // pin status register, one sub-register per pin
  // coding is
  // bit 0: current value
  // bit 1: has gone up since last read
  // bit 2: has gone down since last read
  //  000  - lo
  //  001  - hi
  //  01-  - rising
  //  10-  - falling
  //  11-  - both

//------------------------------------
// CLOCK_TYPE_REG
    #define CTL_SYNC_RISING           0   // Sync clock is rising/both
    #define CTL_SYNC_FALLING          1   // Sync clock is falling/both
    #define CTL_CT_0                  2   // clock type bit 0
    #define CTL_CT_1                  3   // clock type bit 1
    #define CTL_CT_2                  4   // clock type bit 2

//------------------------------------
// Pre/Post counts and timer-counter load.
// COUNTER_TIMER_REG
    // Pre-trigger counter load.
    #define PRE_A                     0   // bits  7..0
    #define PRE_B                     1   // bits  X..8
    // Post-trigger counter load.
    #define POST_A                    4   // bits  7..0
    #define POST_B                    5   // bits  X..8
    // Timer inits.
    #define TCTR_A                    8   // bits 7..0
    #define TCTR_B                    9   // bits X..8

//------------------------------------
// TRIG_OUT_REG
    #define TRIG_OUT_MODE_LO_BIT      0
    #define TRIG_OUT_MODE_HI_BIT      1
  // modes:
      #define TRIG_OUT_MODE_TRIGOUT     0
      #define TRIG_OUT_MODE_XCLK_2      1
      #define TRIG_OUT_MODE_XCLK_4      2
      #define TRIG_OUT_MODE_SCLK_8      3
    #define TRIG_OUT_POLARITY_BIT     5
  // polarity is 0-rising, 1:falling

//------------------------------------
// BRAM address reg
// RAM_ADDR_REG
  // read address shifted in, 6 bits at a time from LSB

//------------------------------------
// EFB_ADDR_REG
  // EFB address shifted in, 4 bits at a time from LSB

//------------------------------------
// EFB_DATA_REG
  // for writes, EFB data shifted in, 4 bits at a time from LSB
  // for reads, returns contents of EFB reg pointed to by ADDR,
  // but WITH A DELAY OF ONE READ!

//------------------------------------
// Scratch register. RW
// SCRATCH_REG
  // 6-bit register, padded with 01

#endif
// EOF ----------------------------------------------------------------
/*
*/
