-----------------------------------------------------------------------
-- fandefs.vhd    Bugblat Fan board definitions
--
-- Initial entry: 05-Jan-14 te
-- see copyright notice at the end of this file
-----------------------------------------------------------------------
library ieee;               use ieee.std_logic_1164.all;
library work;               use work.utils.all;

package defs is
  constant ID       : std_logic_vector(7 downto 0) := x"38";    -- '8'
  constant REVISION : integer := 1;
  constant CHANS    : integer := 8;

  subtype TSig is std_logic_vector(CHANS-1 downto 0);

  ---------------------------------------------------------------------
  -- clock type code
  subtype TClockType is natural range 0 to 7;
  constant CT_X1    : TClockType := 0;
  constant CT_X2    : TClockType := 1;
  constant CT_X4    : TClockType := 2;
  constant CT_X8    : TClockType := 3;
  constant CT_SLOW  : TClockType := 4;
  constant CT_SYNC  : TClockType := 5;

  -- timer/counter bits
  constant TC_BITS        : integer := 10;

  constant SAMPLE_PHASES  : integer := 4;
  type TNybbleSet is array (0 to SAMPLE_PHASES-1) of slv4;

  -- BRAM addresses ---------------------------------------------------
  --
  -- address decode for writing 18-bit vals
  -- 12 11 10  9  8  7  6  5  4  3  2  1  0
  --  -  S  S  S  A  A  A  A  A  A  A  A  A

  -- address decode for 18-bit read access
  -- 12 11 10  9  8  7  6  5  4  3  2  1  0
  --  -  S  S  S  A  A  A  A  A  A  A  A  A
  --
  --  S: BRAM select - max is (0..7)
  --  A: BRAM address
  ---------------------------------------------------------------------
  constant NUMRAMS      : integer := 8;

  constant BRAM_WA_BITS : integer := 12;
  constant BRAM_WA_MAX  : integer := (NUMRAMS*512)-1;   -- write 4K x 18
  constant BRAM_WD_BITS : integer := 18;
  subtype TBramWrAddr is std_logic_vector(BRAM_WA_BITS-1 downto 0);
  subtype TBramWrData is std_logic_vector(BRAM_WD_BITS-1 downto 0);

  constant BRAM_RA_BITS : integer := 12;
  constant BRAM_RA_MAX  : integer := (NUMRAMS*512)-1;   -- read  4K x 18
  constant BRAM_RD_BITS : integer := 18;
  subtype TBramRdAddr is std_logic_vector(BRAM_RA_BITS-1 downto 0);
  subtype TBramRdData is std_logic_vector(BRAM_RD_BITS-1 downto 0);


  -- I2C interface ----------------------------------------------------
  -- read/write from the I2C to the FPGA is over an 8-bit bus
  --            Address bits      Data Bits
  --  Read      from XA register  8-bit from the reg selected by XA
  --  Write     bits 7,6 == '00': write to the XA register
  --            bits 7,6 == '01': write to the register selected by XA

  constant CTL_TYPE_BITS : integer := 2;
  constant CTL_DATA_BITS : integer := 6;
  constant CTL_NBITS     : integer := CTL_TYPE_BITS + CTL_DATA_BITS;

  subtype TincomingTypeRange is integer range 7 downto CTL_DATA_BITS;
  subtype TincomingDataRange is integer range (CTL_DATA_BITS-1) downto 0;

  subtype TctlData is std_logic_vector(CTL_DATA_BITS-1 downto 0);
  subtype TctlType is std_logic_vector(CTL_TYPE_BITS-1 downto 0);

  constant A_ADDR : TctlType := "00";
  constant D_ADDR : TctlType := "01";
  constant T_ADDR : TctlType := "10";
  constant H_ADDR : TctlType := "11";

  subtype TctlSlice is integer range (CTL_NBITS-1) downto CTL_DATA_BITS;

  constant XA_BITS    : integer := 5;                 -- 32 register addresses
  constant XSUBA_BITS : integer := 7;                 -- 128 sub-addresses
  constant XSUBA_MAX  : integer := 2**XSUBA_BITS -1;

  subtype TXARange is integer range XA_BITS-1 downto 0;
  subtype TXA      is integer range 0 to 2**XA_BITS -1;
  subtype TXSubA   is integer range 0 to XSUBA_MAX;

  ---------------------------------------------------------------------
  type XIrec is record          -- write data for regs
    PRdFinished : boolean;      -- registered in clock PRDn goes off
    PWr         : boolean;      -- registered single-clock write strobe
    PA          : TXA;          -- registered incoming addr bus
    PRdSubA     : TXSubA;       -- read sub-address
    PWrSubA     : TXSubA;       -- write sub-address
    PD          : TctlData;     -- registered incoming data bus
  end record XIrec;

  type TCtlRec is record        -- control signals
    Reset,                      -- sync'd to the logic clock
    ResetClock,                 -- specific bit in control register
    Run,
    Stop          : boolean;
    ClockType     : TClockType;
  end record TCtlRec;

  type TClkRec is record        -- clock control signals
    sclk,                       -- system clock, type 125MHz
    xclk          : std_logic;  -- effectively LPC812 "clock out", typ 10MHz
    clocksRunning,
    sampleCE      : boolean;    -- used for slow sampling
  end record TClkRec;

  type TEvalRec is record       -- input to the "eval" RAM lookup table
    Pclk,
    Sclk        : std_logic;
    wrEna       : boolean;
    wrAddr      : slv4;
  end record TEvalRec;

  type Twishbone2pll is record
    clk,
    rst,
    stb,
    we       : std_logic;
    addr     : slv5;
    data     : slv8;
  end record Twishbone2pll;

  type Tpll2wishbone is record
    data     : slv8;
    ack      : std_logic;
  end record Tpll2wishbone;

  --===========================================================
  -- Register Definitions
  --===========================================================

  -- ID register. RO
  constant ID_REG : TXA                                           := 0;


  --------------------------------------
  -- main control register. RW
  constant CONTROL_REG : TXA                                      := 1;
    constant CTL_RESET        : integer := 0;   -- Reset
    constant CTL_RUN          : integer := 1;   -- Run
    constant CTL_STOP         : integer := 2;   -- force a stop
    constant CTL_UNUSED_3     : integer := 3;   -- unused
    constant CTL_RESETCLK     : integer := 4;   -- reset the PLL
    constant CTL_TRIGENA      : integer := 5;
    constant CTL_UNUSED_6     : integer := 6;   -- unused
    constant CTL_CLKSRUNNING  : integer := 7;   -- DCMs locked


  --------------------------------------
  -- main acquisition state machine status reg. RO
  constant STATUS_REG : TXA                                       := 2;
    -- readback Status subregisters
    --  0     Status readback 0
    --  1     Status readback 1         undefined
    --  2     Status readback 2         undefined
    --  3     Status readback 3         undefined
    --
    --  4     Trigger Point Byte 0
    --  5     Trigger Point Byte 1
    --  6     Trigger Point Byte 2      0 if unused
    --  7     Trigger Point Byte 3      0 if unused
    --
    --  8     Final Wr Address Byte 0
    --  9     Final Wr Address Byte 1
    -- 10     Final Wr Address Byte 2   0 if unused
    -- 11     Final Wr Address Byte 3   0 if unused
    constant STATUS_REG_NUM_SUBS  : integer := 16;
    -----------------------------
    -- subaddress 0
    constant STATUS_REG_STATUS    : integer :=  0;
      -- bits 5..0:
      constant LAidleIX      : integer := 1;        -- reported to host PC
      constant LAprefillIX   : integer := 2;
      constant LAsearchIX    : integer := 3;
      constant LAhit1IX      : integer := 4;
      constant LAhit2IX      : integer := 5;
      constant LAtriggeredIX : integer := 6;
      constant LAdoneIX      : integer := 7;
      constant LAnonsense    : integer := 0;
      -- bit 6 - set after all the RAM has been written at least once
      constant STATUS_RAMWRITTEN : integer := 6;
      -- bit 7 - set after the analyser has triggered
      constant STATUS_TRIGGERED  : integer := 7;
    -----------------------------
    -- subaddresses 4..7
    -- trigger point readout
    constant STATUS_REG_TRIG_BYTE_0 : integer := 4;
    constant STATUS_REG_TRIG_BYTE_1 : integer := 5;
    constant STATUS_REG_TRIG_BYTE_2 : integer := 6;
    constant STATUS_REG_TRIG_BYTE_3 : integer := 7;
    -----------------------------
    -- subaddresses 8..11
    -- final RAM write address readout
    constant STATUS_REG_RAMA_BYTE_0 : integer := 8;
    constant STATUS_REG_RAMA_BYTE_1 : integer := 9;
    constant STATUS_REG_RAMA_BYTE_2 : integer := 10;
    constant STATUS_REG_RAMA_BYTE_3 : integer := 11;


  --------------------------------------
  -- pin status readout RO
  constant PIN_STATUS_REG : TXA                                   := 3;
    -- pin status register, one sub-register per pin
    -- coding is
    -- bit 0: current value
    -- bit 1: has gone up since last read
    -- bit 2: has gone down since last read
    --  000  - lo
    --  001  - hi
    --  01-  - rising
    --  10-  - falling
    --  11-  - both


  --------------------------------------
  constant CLOCK_TYPE_REG : TXA                                   := 4;
    constant CTL_SYNC_RISING  : integer := 0;   -- Sync clock is rising/both
    constant CTL_SYNC_FALLING : integer := 1;   -- Sync clock is falling/both
    constant CTL_CT_0         : integer := 2;   -- clock type bit 0
    constant CTL_CT_1         : integer := 3;   -- clock type bit 1
    constant CTL_CT_2         : integer := 4;   -- clock type bit 2


  --------------------------------------
  -- Pre/Post counts and timer-counter load.
  constant COUNTER_TIMER_REG : TXA                                := 5;
    -- Pre-trigger counter load.
    constant PRE_A         : integer := 0;   -- bits  7..0
    constant PRE_B         : integer := 1;   -- bits  X..8
    -- Post-trigger counter load.
    constant POST_A        : integer := 4;   -- bits  7..0
    constant POST_B        : integer := 5;   -- bits  X..8
    -- Timer inits.
    constant TCTR_A        : integer := 8;   -- bits 7..0
    constant TCTR_B        : integer := 9;   -- bits X..8


  --------------------------------------
  constant MATCH_COMBINE_REG : TXA                                := 6;


  --------------------------------------
  constant MATCH_EVAL_REG : TXA                                   := 7;


  --------------------------------------
  constant SM_EVAL_REG : TXA                                      := 8;


  --------------------------------------
  constant TRIG_OUT_REG : TXA                                     := 9;
    constant TRIG_OUT_MODE_LO_BIT  : integer := 0;
    constant TRIG_OUT_MODE_HI_BIT  : integer := 1;
    -- modes:
      constant TRIG_OUT_MODE_TRIGOUT  : integer := 0;
      constant TRIG_OUT_MODE_XCLK_2   : integer := 1;
      constant TRIG_OUT_MODE_XCLK_4   : integer := 2;
      constant TRIG_OUT_MODE_SCLK_8   : integer := 3;
    constant TRIG_OUT_POLARITY_BIT : integer := 5;
    -- polarity is 0-rising, 1:falling


  --------------------------------------
  -- BRAM address reg
  constant RAM_ADDR_REG : TXA                                     := 10;
    -- read address shifted in, 6 bits at a time from LSB


  --------------------------------------
  constant RAM_DATA_REG : TXA                                     := 11;


  --------------------------------------
  constant EFB_ADDR_REG : TXA                                     := 12;
    -- EFB address shifted in, 4 bits at a time from LSB


  --------------------------------------
  constant EFB_DATA_REG : TXA                                     := 13;
    -- for writes, EFB data shifted in, 4 bits at a time from LSB
    -- for reads, returns contents of EFB reg pointed to by ADDR,
    -- but WITH A DELAY OF ONE READ!


  --------------------------------------
  -- Scratch register. RW
  constant SCRATCH_REG : TXA                                      := 31;
    -- 6-bit register, paded with 01


-----------------------------------------------------------------------
end package defs;

-----------------------------------------------------------------------
package body defs is
end package body defs;

--********************************************************************
-- Copyright (c) 2004-2014 Tim Eccles and Bugblat Ltd. All rights reserved.
--
-- Permission is hereby granted, free of charge, to any person obtaining
-- a copy of this software and associated documentation files (the
-- "Software"), to deal in the Software without restriction, including
-- without limitation the rights to use, copy, modify, merge, publish,
-- distribute, sublicense, and/or sell copies of the Software, and to
-- permit persons to whom the Software is furnished to do so, subject to
-- the following conditions:
--
-- The above copyright notice and this permission notice shall be
-- included in all copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
-- EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
-- MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
-- IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
-- CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
-- TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
-- SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
--********************************************************************

-- EOF fandefs.vhd ---------------------------------------------------
