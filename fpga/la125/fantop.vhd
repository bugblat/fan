-----------------------------------------------------------------------
-- fantop.vhd    Bugblat fan analyser top level
--
-- Initial entry: 05-Jan-12 te
-- see copyright notice in fandefs.vhd
-----------------------------------------------------------------------
library ieee;       use ieee.std_logic_1164.all, ieee.numeric_std.all;
library work;       use work.attributes.all, work.utils.all, work.defs.all;
library machxo2;    use machxo2.components.all;

entity fantop is
  port (
    ID0, ID1      : in    std_logic;
    utxd          : in    std_logic;    -- USB Tx, FPGA Rx
    urxd          : out   std_logic;    -- USB Rx, FPGA Tx
    clk24,
    RST,
    SUSPn         : in    std_logic;
    SigIn         : in    TSig;
    -- synthesis translate_off
    TP11, TP13,
    clksrunning,
    sampclk,
    -- synthesis translate_on
    vrefPWM,
    trigOut,
    RedLed,
    GreenLed      : out   std_logic   );

end fantop;

architecture rtl of fantop is

  ------------------------------------------
  component fanuctl is port (
      rxd         : in    std_logic;
      txd         : out   std_logic;
      xclk        : in    std_logic;
      XI          : out   XIrec;
      XO          : in    slv8          );
  end component fanuctl;
  ------------------------------------------
  component fanxlayer is
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
      GreenLed    : out   std_logic       );
  end component fanxlayer;
  ------------------------------------------
  component fanclock is
    port (
      clk24       : in    std_logic;
      reset       : in    boolean;
      ClkRec      : out   TClkRec;
      wb2pll      : in    Twishbone2pll;
      pll2wb      : out   Tpll2wishbone   );
  end component fanclock;
  ------------------------------------------
  component fanwb is
    port (
      xclk        : in    std_logic;
      XI          : in    XIrec;
      XO          : out   slv8;
      refPWM      : out   std_logic;
      wb2pll      : out   Twishbone2pll;
      pll2wb      : in    Tpll2wishbone;
      ctlReset    : in    boolean         );
  end component fanwb;
  ------------------------------------------

  signal  ClkRec        : TClkRec;
  signal  XI            : XIrec;
  signal  XO, XOx, XOwb : slv8;
  signal  wb2pll        : Twishbone2pll;
  signal  pll2wb        : Tpll2wishbone;
  signal  ID0_i, ID1_i,
          GSRn,
          red, green    : std_logic;
  signal  ctlReset,
          resetClock    : boolean;

  attribute PULLMODE of ID0_i : signal is "DOWN";
  attribute PULLMODE of ID1_i : signal is "UP"  ;

begin
  IBid0 : IB port map ( I=>ID0, O=>ID0_i );
  IBid1 : IB port map ( I=>ID1, O=>ID1_i );

  GSRn <= '0' when (RST='1' or SUSPn='0') else '1';       -- global reset
  GSR_GSR : GSR port map ( GSR=>GSRn );

  XO <= XOx or XOwb;

  -----------------------------------------------
  -- control via UART
  UCTL : fanuctl port map  ( rxd            => utxd,
                             txd            => urxd,
                             xclk           => ClkRec.xclk,
                             XI             => XI,
                             XO             => XO           );
  -----------------------------------------------
  -- instantiate the Xbus-level logic
  BXL: fanxlayer  port map ( ID0            => ID0_i,
                             ID1            => ID1_i,
                             ClkRec         => ClkRec,
                             sigIn          => sigIn,
                             XI             => XI,
                             XO             => XOx,
                             ctlReset       => ctlReset,
                             resetClock     => resetClock,
                             trigOut        => trigOut,
                             RedLed         => red,
                             GreenLed       => green        );
  -----------------------------------------------
  -- instantiate the clock circuitry
  KLK: fanclock   port map ( clk24          => clk24,
                             reset          => resetClock,
                             ClkRec         => ClkRec,
                             wb2pll         => wb2pll,
                             pll2wb         => pll2wb       );
  -----------------------------------------------
  -- instantiate the wishbone interface
  WB : fanwb     port map (  xclk           => ClkRec.xclk,
                             XI             => XI,
                             XO             => XOwb,
                             refPWM         => vrefPWM,
                             wb2pll         => wb2pll,
                             pll2wb         => pll2wb,
                             ctlReset       => ctlReset     );
  -----------------------------------------------
  -- for simulation
  -- synthesis translate_off
  clksrunning <= to_sl(ClkRec.ClocksRunning);
  sampclk     <= ClkRec.sclk;
  -- synthesis translate_on
  ---------------------------------------------------------------------
  -- force the LEDs OFF (i.e. Lo) when GSRn is asserted Lo
  RedLed   <= red   and GSRn;
  GreenLed <= green and GSRn;

  -------------------------------------------------------------------
  -- test sigs
  -- synthesis translate_off
  TMP_TST: block
    signal kx, ks: std_logic := '1';
  begin
    process (ClkRec.xclk)
    begin
      if rising_edge(ClkRec.xclk) then
        kx <= not kx;
      end if;
    end process;

    process (ClkRec.sclk)
    begin
      if rising_edge(ClkRec.sclk) then
        ks <= not ks;
      end if;
    end process;

    TP11 <= kx;
    TP13 <= ks;
  end block TMP_TST;
  -- synthesis translate_on

end rtl;    -- EOF fantop.vhd
