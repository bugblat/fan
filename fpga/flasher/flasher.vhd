-----------------------------------------------------------------------
-- flasher.vhd
--
-- Initial entry: 21-Apr-11 te
--
-- VHDL hierarchy is
--      flasher             top level
--      simpleFlasher.vhd   does the work!
--
-----------------------------------------------------------------------
-- see copyright notice in fandefs.vhd
-----------------------------------------------------------------------
library IEEE;       use IEEE.std_logic_1164.all;
library machxo2;    use machxo2.components.all;

--=====================================================================
entity flasher is
   port ( RST,
          SUSPn     : in  std_logic;
          RedLed,
          GreenLed  : out std_logic   );
end flasher;

--=====================================================================
architecture rtl of flasher is
  -----------------------------------------------
  component simpleFlasher is port ( red, green : out std_logic );
  end component simpleFlasher;
  -----------------------------------------------

  signal GSRn, red, green : std_logic;

begin
  GSRn <= '0' when (RST='1' or SUSPn='0') else '1';       -- global reset
  GSR_GSR : GSR port map ( GSR=>GSRn );

  -----------------------------------------------
  -- LED flasher
  F: simpleFlasher port map ( red   => red,
                              green => green  );
  -- force the LEDs OFF (i.e. Lo) when GSRn is asserted Lo
  RedLed <= red and GSRn;
  GreenLed <= green and GSRn;

end rtl;
-- EOF ----------------------------------------------------------------
