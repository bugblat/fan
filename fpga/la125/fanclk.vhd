-----------------------------------------------------------------------
-- fanclk.vhd    Bugblat fan logic analyser clocking
--
-- Initial entry: 05-Jan-12 te
--
-- see copyright notice in fandefs.vhd
-----------------------------------------------------------------------
-- clk24 drives the PLL. The PLL is then divided down to sclk.
-----------------------------------------------------------------------
library ieee;           use ieee.std_logic_1164.all;
library work;           use work.utils.all;
                        use work.defs.all;
library machxo2;        use machxo2.components.all;

entity xpll is port ( reset     : in  boolean;
                      clk24     : in  std_logic;
                      locked    : out boolean;
                      sclk      : out std_logic;
                      wb2pll    : in  Twishbone2pll;
                      pll2wb    : out Tpll2wishbone   );
 attribute dont_touch : boolean;
 attribute dont_touch of xpll : entity is true;
end xpll;

architecture struct of xpll is
  attribute syn_hier              : string;
  attribute syn_hier    of struct : architecture is "hard";
  attribute syn_noprune           : boolean;
  attribute syn_noprune of struct : architecture is true;

  signal  plla_locked,
          plla_int_feedback,
          plla_clk_os,
          plla_clk_os2,
          plla_clk_os3, zlo     : std_logic;

  -------------------------------------------------
  attribute STDBY_ENABLE        : string;
  attribute FREQUENCY_PIN_CLKOP : string;
  attribute FREQUENCY_PIN_CLKOS : string;
  attribute FREQUENCY_PIN_CLKI  : string;
  attribute ICP_CURRENT         : string;
  attribute LPF_RESISTOR        : string;

  attribute STDBY_ENABLE         of PLLA : label is "DISABLED";
  attribute FREQUENCY_PIN_CLKI   of PLLA : label is "24.0";
  attribute FREQUENCY_PIN_CLKOP  of PLLA : label is "125.0";
  attribute FREQUENCY_PIN_CLKOS  of PLLA : label is "125.0";
--attribute FREQUENCY_PIN_CLKOS2 of PLLA : label is "125.0";
--attribute FREQUENCY_PIN_CLKOS3 of PLLA : label is "100.0";

  -- the next two mysterious numbers were checked via IPexpress
  -- that doesn't mean they are correct!
  attribute ICP_CURRENT         of PLLA : label is "7";
  attribute LPF_RESISTOR        of PLLA : label is "8";

begin
  scuba_vlo_inst: VLO port map (Z=>zlo);

  ---------------------------------------------
  PLLA: EHXPLLJ
    generic map ( DDRST_ENA         => "DISABLED",
                  DCRST_ENA         => "DISABLED",
                  MRST_ENA          => "DISABLED",
                  INTFB_WAKE        => "DISABLED",
                  DPHASE_SOURCE     => "DISABLED",

                  PLLRST_ENA        => "ENABLED",
                  PLL_USE_WB        => "ENABLED",

                  CLKOP_FPHASE      =>  0,
                  CLKOS_FPHASE      =>  0,
                  CLKOS2_FPHASE     =>  0,
                  CLKOS3_FPHASE     =>  0,

                  CLKOP_CPHASE      =>  0,
                  CLKOS_CPHASE      =>  0,
                  CLKOS2_CPHASE     =>  0,
                  CLKOS3_CPHASE     =>  4,

                  CLKOP_TRIM_DELAY  =>  0,
                  CLKOP_TRIM_POL    => "RISING",
                  CLKOS_TRIM_DELAY  =>  0,
                  CLKOS_TRIM_POL    => "FALLING",

                  CLKOP_ENABLE      => "ENABLED",     -- A
                  CLKOS_ENABLE      => "ENABLED",     -- B
                  CLKOS2_ENABLE     => "ENABLED",     -- C
                  CLKOS3_ENABLE     => "ENABLED",     -- D

                  VCO_BYPASS_A0     => "DISABLED",
                  VCO_BYPASS_B0     => "DISABLED",
                  VCO_BYPASS_C0     => "DISABLED",
                  VCO_BYPASS_D0     => "DISABLED",

                  PLL_LOCK_MODE     =>  0,

          -- fractional divider
          -- 25/24 = 1.041666 = 1 + 0.041666 = 1 + 2731/65536
                  FRACN_DIV         =>  4 * 2731,     -- 25MHz down to 24MHz
                  FRACN_ENABLE      => "ENABLED",

                  PREDIVIDER_MUXA1  =>  2,            -- A from B
                  CLKOP_DIV         =>  1,            -- start by div by 1
                  OUTDIVIDER_MUXA2  => "DIVA",

                  PREDIVIDER_MUXB1  =>  3,            -- B from C
                  CLKOS_DIV         =>  1,            -- start by div by 1
                  OUTDIVIDER_MUXB2  => "DIVB",

                  PREDIVIDER_MUXC1  =>  0,            -- C from PLL
                  CLKOS2_DIV        =>  4,            -- 500MHz -> 125MHz
                  OUTDIVIDER_MUXC2  => "DIVC",

                  PREDIVIDER_MUXD1  =>  0,            -- D from PLL
                  CLKOS3_DIV        =>  5,            -- 500MHz -> 100MHz
                  OUTDIVIDER_MUXD2  => "DIVD",

                  CLKFB_DIV         =>  4,            -- 100MHz from DivD
                  CLKI_DIV          =>  1,
                  FEEDBK_PATH       => "INT_DIVD"    )
    port map (CLKI        => clk24,
              CLKFB       => plla_int_feedback,
              PHASESEL1   => zlo,
              PHASESEL0   => zlo,
              PHASEDIR    => zlo,
              PHASESTEP   => zlo,
              LOADREG     => zlo,
              STDBY       => zlo,
              PLLWAKESYNC => zlo,
              RST         => to_sl(reset),
              RESETM      => zlo,
              RESETC      => zlo,
              RESETD      => zlo,
              ENCLKOP     => zlo,
              ENCLKOS     => zlo,
              ENCLKOS2    => zlo,
              ENCLKOS3    => zlo,
              PLLCLK      => wb2pll.clk,
              PLLRST      => wb2pll.rst,
              PLLSTB      => wb2pll.stb,
              PLLWE       => wb2pll.we,
              PLLADDR4    => wb2pll.addr(4),
              PLLADDR3    => wb2pll.addr(3),
              PLLADDR2    => wb2pll.addr(2),
              PLLADDR1    => wb2pll.addr(1),
              PLLADDR0    => wb2pll.addr(0),
              PLLDATI7    => wb2pll.data(7),
              PLLDATI6    => wb2pll.data(6),
              PLLDATI5    => wb2pll.data(5),
              PLLDATI4    => wb2pll.data(4),
              PLLDATI3    => wb2pll.data(3),
              PLLDATI2    => wb2pll.data(2),
              PLLDATI1    => wb2pll.data(1),
              PLLDATI0    => wb2pll.data(0),
              CLKOP       => sclk,              -- sclk output
              CLKOS       => plla_clk_os,
              CLKOS2      => plla_clk_os2,
              CLKOS3      => plla_clk_os3,
              LOCK        => plla_locked,
              INTLOCK     => open,
              REFCLK      => open,
              CLKINTFB    => plla_int_feedback,
              DPHSRC      => open,
              PLLACK      => pll2wb.ack,
              PLLDATO7    => pll2wb.data(7),
              PLLDATO6    => pll2wb.data(6),
              PLLDATO5    => pll2wb.data(5),
              PLLDATO4    => pll2wb.data(4),
              PLLDATO3    => pll2wb.data(3),
              PLLDATO2    => pll2wb.data(2),
              PLLDATO1    => pll2wb.data(1),
              PLLDATO0    => pll2wb.data(0)   );

  locked <= (plla_locked = '1');

end struct;

-----------------------------------------------------------------------
library ieee;           use ieee.std_logic_1164.all;
                        use ieee.numeric_std.all;
library work;           use work.defs.all;
                        use work.attributes.all;
                        use work.utils.all;

entity fanclock is port (
          clk24     : in  std_logic;
          reset     : in  boolean;
          ClkRec    : out TClkRec;
          wb2pll    : in  Twishbone2pll;
          pll2wb    : out Tpll2wishbone   );
end fanclock;

architecture rtl of fanclock is
  -------------------------------------------------
  component xpll is port ( reset    : in  boolean;
                           clk24    : in  std_logic;
                           locked   : out boolean;
                           sclk     : out std_logic;
                           wb2pll   : in  Twishbone2pll;
                           pll2wb   : out Tpll2wishbone   );
  end component xpll;

  -------------------------------------------------
  signal sclk   : std_logic;    -- initially 100MHz
  signal locked : boolean;
begin

  -------------------------------------------------
  myPLL: xpll port map ( reset  => reset,
                         clk24  => clk24,
                         locked => locked,
                         sclk   => sclk,
                         wb2pll => wb2pll,
                         pll2wb => pll2wb   );

  ClkRec.sclk          <= sclk;
  ClkRec.xclk          <= clk24;
  ClkRec.clocksRunning <= locked;
  ClkRec.sampleCE      <= true;

end rtl;
-----------------------------------------------------------------------
-- EOF fanclk.vhd
