-----------------------------------------------------------------------
-- fanxlayer.vhd    Bugblat fan analyser X-bus level
--
-- Initial entry: 05-Jan-12 te
-- see copyright notice in fandefs.vhd
-----------------------------------------------------------------------
library ieee;     use ieee.std_logic_1164.all, ieee.numeric_std.all;
library work;     use work.utils.all, work.defs.all;

entity fanxlayer is
  port (
    ID0, ID1    : in    std_logic;
    ClkRec      : in    TClkRec;
    sigIn       : in    Tsig;
    XI          : in    XIrec;
    XO          : out   slv8;
    ctlReset,
    resetClock  : out   boolean;
    trigOut,
    RedLed,
    GreenLed    : out   std_logic   );
end fanxlayer;

architecture rtl of fanxlayer is
  ------------------------------------------
  component fanctl is
    port (
      ID0,
      ID1,
      xclk,
      sclk        : in    std_logic;
      CtlRec      : out   TCtlRec;
      XI          : in    XIrec;
      XO          : out   slv8            );
  end component fanctl;
  ------------------------------------------
  component fansm is
    port (
      ClkRec      : in    TClkRec;
      CtlRec      : in    TCtlRec;
      sigIn       : in    Tsig;
      extraHit    : in    boolean;
      XI          : in    XIrec;
      XO          : out   slv8;
      trigOut,
      RedLed,
      GreenLed    : out   std_logic    );
  end component fansm;
  ------------------------------------------

  signal  CtlRec      : TCtlRec;
  signal  XOctl, XOsm : slv8;

begin
  ----------------------------------------------
  -- instantiate the run/stop/... control logic and ID registers
  CTL: fanctl     port map ( ID0        => ID0,
                             ID1        => ID1,
                             xclk       => ClkRec.xclk,
                             sclk       => ClkRec.sclk,
                             CtlRec     => CtlRec,
                             XI         => XI,
                             XO         => XOctl        );

  ----------------------------------------------
  -- instantiate the state machine and data path
  SM : fansm     port map (  ClkRec     => ClkRec,
                             CtlRec     => CtlRec,
                             SigIn      => SigIn,
                             extraHit   => false,     -- nothing special
                             XI         => XI,
                             XO         => XOsm,
                             trigOut    => trigOut,
                             RedLed     => RedLed,
                             GreenLed   => GreenLed     );
  ----------------------------------------------

  XO <= XOctl or XOsm;
  resetClock <= CtlRec.resetClock;
  ctlReset   <= CtlRec.reset;

end rtl;
-- EOF fanxlayer.vhd --------------------------------------------------
