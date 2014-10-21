-----------------------------------------------------------------------
-- fanact.vhd    Bugblat fan -- reports the signal pin status
--
-- Initial entry: 05-Jan-12 te
--
-- Copyright (c) 2001 to 2014  te
-- see copyright notice in fandefs.vhd
-----------------------------------------------------------------------
library IEEE;                 use IEEE.std_logic_1164.all;
library work;                 use work.utils.all, work.defs.all;

entity activity is port (
            xclk  : in  std_logic;
            sclk  : in  std_logic;
            sig   : in  TSig;
            XI    : in  XIrec;
            XO    : out slv8      );
end activity;

architecture rtl of activity is
  attribute keep_hierarchy : string;
  attribute keep_hierarchy of rtl: architecture is "true";

  type TXOreg is array (0 to CHANS-1) of slv3;
  signal XOreg : TXOreg;

begin
  -- instantiate the channels
  G_ACT: for i in Sig'range generate
    signal S, LastS, SigReg     : std_logic;
    signal Rising,
           RisingReg,             -- have seen a rising edge
           Falling,
           FallingReg,            -- have seen a falling edge
           Clear      : boolean;  -- clear the event regs
  begin
    S <= Sig(i);


    -- register the incoming signal
    process (sclk) begin
      if rising_edge(sclk) then
        LastS <= S;
      end if;
    end process;


    -- detect edges
    process (sclk, Clear) begin
      if Clear then
        Rising  <= false;
        Falling <= false;
      elsif rising_edge(sclk) then
        if (LastS='0') and (S='1') then
          Rising <= true;
        end if;
        if (LastS='1') and (S='0') then
          Falling <= true;
        end if;
      end if;
    end process;


    -- register Sig/Rising/Falling to make timing easier
    process (xclk) begin
      if rising_edge(xclk) then
        SigReg     <= S;
        RisingReg  <= Rising;
        FallingReg <= Falling;
      end if;
    end process;


      -- bit 0: current value
      -- bit 1: has gone up since last read
      -- bit 2: has gone down since last read
    XOreg(i) <= to_sl(FallingReg) & to_sl(RisingReg) & SigReg;


    -- clear the events after a readback.
    -- could save a few gates by clearing them all after the last one is read
    process (xclk) begin
      if rising_edge(xclk) then
        Clear <= XI.PRdFinished and (XI.PA=PIN_STATUS_REG)
                                    and ((XI.PRdSubA mod CHANS)=i);
      end if;
    end process;

  end generate G_ACT;


  -----------------------------------------------------
  -- readback
  process (xclk)
    variable n: integer range 0 to CHANS-1;
  begin
    if rising_edge(xclk) then
      n := XI.PRdSubA mod CHANS;

      if  XI.PA = PIN_STATUS_REG then
        XO(7 downto 4) <= n2slv(n, 4);
        XO(3)          <= '0';
        XO(2 downto 0) <= XOreg(n);
      else
        XO <= (others=>'0');
      end if;

    end if;
  end process;

end rtl;
-- EOF fanact.vhd -----------------------------------------------------
