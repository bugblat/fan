-----------------------------------------------------------------------
-- simpleFlasher.vhd    LED simpleFlasher
--
-- Initial entry: 05-Jan-12 te
-- see copyright notice in fandefs.vhd
-----------------------------------------------------------------------
-- there must be a thousand ways of doing this!
-----------------------------------------------------------------------
library ieee;                 use ieee.std_logic_1164.all;
                              use ieee.numeric_std.all;
                              use ieee.math_real.all;
library machxo2;              use machxo2.components.all;
library work;                 use work.utils.all;

entity simpleFlasher is port ( red, green : out std_logic );
end simpleFlasher;

architecture rtl of simpleFlasher is

  attribute keep_hierarchy : string;
  attribute keep_hierarchy of rtl: architecture is "true";

  ---------------------------------------------------------------------
  component downCounter is generic ( BITS : integer := 10);
    port (
      Clk          : in  std_logic;
      InitialVal   : in  unsigned(BITS-1 downto 0);
      LoadN,
      CE           : in  std_logic;
      zero         : out boolean         );
  end component downCounter;
  ---------------------------------------------------------------------
  -- Calculate the number of bits required to represent a given value
  function NumBits(val : integer) return integer is
    variable result : integer;
  begin
    if val=0 then
      result := 0;
    else
      result  := natural(ceil(log2(real(val))));
    end if;
    return result;
  end;
  ---------------------------------------------------------------------

  constant OSC_RATE : integer := 2080000;
  constant OSC_STR  : string  := "2.08";
  constant TICK_RATE: integer := 150;

  attribute nom_freq : string;
  attribute nom_freq of oscinst0 : label is OSC_STR;

  signal osc : std_logic;

  -- each slot containing 2**B ticks
  constant B: integer := 5;
  signal Tick : boolean;

  -- the ramping LED signal
  signal LedOn: boolean;

  -- red/green outputs
  signal R  : std_logic := '0';
  signal G  : std_logic;

  -- phase accumulator for the PWM
  signal Accum   : unsigned(B   downto 0) := (others=>'0');

  -- saw-tooth incrementing Phase Delta register
  signal DeltaReg: unsigned(B+1 downto 0) := (others=>'0');

  -- low bits of DeltaReg
  signal Delta   : unsigned(B-1 downto 0);

  -- high bits of DeltaReg
  signal LedPhase: unsigned(1 downto 0);

begin
  -- instantiate the internal osc
  OSCInst0: osch
    -- synthesis translate_off
    generic map ( nom_freq => OSC_STR )
    -- synthesis translate_on
    port map ( stdby    => '0',         -- could use a standby signal
               osc      => osc,
               sedstdby => open   );    -- for simulation, use stdby_sed sig


  -- generate the Tick clock
  TICK_BLOCK: block
    -- divide down from 2MHz to approx 150Hz
    constant FREQ_DIV: integer := OSC_RATE/TICK_RATE;

    constant TICK_LEN: integer := FREQ_DIV
    -- synthesis translate_off
            - FREQ_DIV + 8              -- make the simulation reasonable!
    -- synthesis translate_on
      ;
    constant CLEN: integer := NumBits(TICK_LEN);
    constant DIV : unsigned(CLEN-1 downto 0) := to_unsigned(TICK_LEN, CLEN);

    signal LoadN: std_logic;
  begin
    LoadN <= '0' when Tick else '1';
    TK:  downCounter generic map ( BITS => CLEN )
                     port map    ( Clk        => osc,
                                   InitialVal => DIV,
                                   LoadN      => LoadN,
                                   CE         => '1',
                                   zero       => Tick );

  end block TICK_BLOCK;

  -- increment the Delta register and the 0.1.2.3 phase counter
  -- DeltaReg is unsigned, so it rolls round from all-1s to zero
  process (osc)
  begin
    if rising_edge(osc) then
      if Tick then
        DeltaReg <= DeltaReg+1;
      end if;
    end if;
  end process;
  -- extract the Delta and Phase bits.
  -- alternatively, this could be done via a VHDL signal alias.
  Delta    <= DeltaReg(Delta'range);
  LedPhase <= DeltaReg(DeltaReg'high downto DeltaReg'high-1);


  -- generate the LED PWM signal
  process (osc)
    variable acc, delt: unsigned(Accum'range);
  begin
    if rising_edge(osc) then
      if Tick then
        Accum <= (others=>'0');
      else
        acc := '0' & Accum(B-1 downto 0);   -- clear overflow to zero
        delt:= '0' & Delta;                 -- bit-extend with zero
        Accum <= acc + delt;
      end if;

      LedOn <= (Accum(B) = '1');            -- overflow drives LED

      R <= not to_sl(((LedPhase=0) and LedOn) or ((LedPhase=1) and not LedOn));
      G <= not to_sl(((LedPhase=2) and LedOn) or ((LedPhase=3) and not LedOn));
    end if;
  end process;

  red   <= R;
  green <= G;

end rtl;

-- EOF simpleFlasher.vhd
