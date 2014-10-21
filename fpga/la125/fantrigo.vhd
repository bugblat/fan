-----------------------------------------------------------------------
-- fantrigo.vhd   Bugblat fan logic analyser trigger out
--
-- Initial entry: 05-Jan-12 te
--
-- see copyright notice in fandefs.vhd
-----------------------------------------------------------------------
library ieee;           use ieee.std_logic_1164.all, ieee.numeric_std.all;
library work;           use work.defs.all, work.utils.all;
library machxo2;        use machxo2.components.all;

entity triggerOut is port ( sclk,
                            xclk      : in  std_logic;
                            XI        : in  XIrec;
                            triggered : in  boolean;
                            trigOut   : out std_logic   );
end triggerOut;

architecture rtl of triggerOut is
  ---------------------------------------------------------------------
  -- trigger out for approx 250ns (approx 7 xclks)
  constant TO_CTR_MAX : integer := 7;
  signal toCount      : integer range 0 to TO_CTR_MAX := 0;
  signal sCounter     : unsigned(2 downto 0) := (others=>'0');
  signal xCounter     : unsigned(1 downto 0) := (others=>'0');

  signal trigOutMode  : integer range 0 to 3 := 0;
  signal invPolarity  : std_logic            := '0';
  signal toFlop       : std_logic            := '0';
  signal toMode, x2Mode, x4Mode, soMode, toClear : boolean;

  attribute GSR : string;
  attribute GSR of trigOutMode : signal is "DISABLED";
  attribute GSR of invPolarity : signal is "DISABLED";

begin
  process (xclk)
    variable countEnable : boolean;
  begin
    if rising_edge(xclk) then
      if (XI.PA = TRIG_OUT_REG) and XI.PWr then
        trigOutMode <=
            toInteger(XI.PD(TRIG_OUT_MODE_HI_BIT downto TRIG_OUT_MODE_LO_BIT));
        invPolarity <= XI.PD(TRIG_OUT_POLARITY_BIT);
      end if;
    end if;
  end process;

  toMode <= (trigOutMode=0);
  x2Mode <= (trigOutMode=1);
  x4Mode <= (trigOutMode=2);
  soMode <= (trigOutMode=3);

  -- to mode ---------------------------------
  process (xclk, triggered)
  begin
    if triggered then
      toFlop <= '1';
    elsif rising_edge(xclk) then
      if toClear then
        toFlop <= '0';
      end if;
    end if;
  end process;

  process (xclk)
  begin
    if rising_edge(xclk) then
      if toFlop='1' then
        toCount <= (toCount+1) mod (TO_CTR_MAX+1);
      else
        toCount <= 0;
      end if;
      toClear <= (toCount = TO_CTR_MAX);
    end if;
  end process;

  -- x2/4 mode ---------------------------------
  process (xclk) begin
    if rising_edge(xclk) then
      xCounter <= xCounter +1;
    end if;
  end process;

  -- so mode ---------------------------------
  process (sclk) begin
    if rising_edge(sclk) then
      sCounter <= sCounter +1;
    end if;
  end process;


  -- extra inverter inserted - there's an '04 inverter on the board
  trigOut <= not(toFlop xor invPolarity) when toMode
                        else xCounter(0) when x2Mode
                        else xCounter(1) when x4Mode
                        else sCounter(2) when soMode
                        else '0';

end rtl;
-- EOF fantrigo.vhd ----------------------------------------------------
