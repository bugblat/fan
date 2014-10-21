-----------------------------------------------------------------------
-- downCounter.vhd
--
-- Initial entry: 05-Jan-12 te
-- see copyright notice in fandefs.vhd
-----------------------------------------------------------------------
-- downCounter is very efficient.
-- The outgoing signal is driven by the MSB as the counter underflows
-- from zero to all-1s. For instance, ...->000000->111111->...
-----------------------------------------------------------------------
library ieee;                 use ieee.std_logic_1164.all;
                              use ieee.numeric_std.all;
library work;                 use work.utils.all;

entity downCounter is
  generic ( BITS : integer := 10 );
  port (
    Clk          : in  std_logic;
    InitialVal   : in  unsigned(BITS-1 downto 0);
    LoadN,
    CE           : in  std_logic;
    zero         : out boolean         );
end downCounter;

architecture struct of downCounter is
  attribute keep_hierarchy : string;
  attribute keep_hierarchy of struct: architecture is "true";

  -- extended by one bit to get the carry-out
  signal counter : unsigned(BITS downto 0);
begin

  process (Clk) begin
    if rising_edge(Clk) then
      if CE='1' then
        if LoadN='0' then
          counter <= '0' & InitialVal;
        else
          counter <= counter -1;
        end if;
      end if;
    end if;
  end process;

  zero  <= counter(BITS) = '1';
end struct;

-- EOF downCounter.vhd

