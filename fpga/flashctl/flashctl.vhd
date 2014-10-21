-----------------------------------------------------------------------
-- flashctl.vhd
--
-- Initial entry: 21-Apr-11 te
--
-- VHDL hierarchy is
--      flasher             top level
--      fanuctl.vhd         UART interface to USB
--        utils.vhd
--        fandefs.vhd
--
-----------------------------------------------------------------------
-- see copyright notice in fandefs.vhd
-----------------------------------------------------------------------
library ieee;       use ieee.std_logic_1164.all, ieee.numeric_std.all;
library work;       use work.utils.all, work.defs.all;
library machxo2;    use machxo2.components.all;

--=====================================================================
entity flashctl is
   port ( utxd      : in  std_logic;      -- USB Tx, FPGA Rx
          urxd      : out std_logic;      -- USB Rx, FPGA Tx
          clk24,
          RST,
          SUSPn     : in  std_logic;
          RedLed,
          GreenLed  : out std_logic   );
end flashctl;

--=====================================================================
architecture rtl of flashctl is
  -----------------------------------------------
  component fanuctl is port (
      rxd           : in    std_logic;
      txd           : out   std_logic;
      xclk          : in    std_logic;
      XI            : out   XIrec;
      XO            : in    slv8       );
  end component fanuctl;
  -----------------------------------------------
  subtype TidInt is integer range 0 to 255;
  type TidSet is array (0 to 15) of TidInt;

  function makeIdArray(s: string) return TidSet is
    constant ss: string(1 to s'length) := s;
    variable answer: TidSet;
    variable c: integer;
  begin
    c := character'pos(' ');
    for i in 0 to 15 loop
      answer(i) := c;
    end loop;
    for i in ss'range loop
      answer(i-1) := character'pos(ss(i));
    end loop;
    return answer;
  end function;
  -----------------------------------------------

  alias   xclk    : std_logic is clk24;

  signal  XI      : XIrec := (  PRdFinished => false
                             ,  PWr         => false
                             ,  PA          => 0
                             ,  PRdSubA     => 0
                             ,  PWrSubA     => 0
                             ,  PD          => (others=>'0'));
  signal  XO      : slv8  := (others=>'0');
  signal  GSRn
        , osc
        , flash
        , redX
        , greenX  : std_logic;

  constant THE_ID_REG       : TXA := 0;
  constant THE_MISC_REG     : TXA := 2;
  constant THE_RED_REG      : TXA := 3;
  constant THE_GREEN_REG    : TXA := 4;

  -- Misc register
  subtype TMisc is integer range 0 to 3;
  constant  LED_ALTERNATING : TMisc := 0;
  constant  LED_SYNC        : TMisc := 1;
  constant  LED_OFF         : TMisc := 2;
  constant  LED_ON          : TMisc := 3;

  signal  miscReg : TMisc := LED_SYNC;

  -- Red and green regs
  constant BRIGHT_MAX: integer := 63;
  subtype TBright is integer range 0 to BRIGHT_MAX;
  signal  redReg        : TBright := BRIGHT_MAX/2;
  signal  greenReg      : TBright := BRIGHT_MAX/2;
  signal  redCounter    : TBright := 0;
  signal  greenCounter  : TBright := 0;

  signal  counter : unsigned(19 downto 0);

  constant id : TidSet := makeIdArray("flashCtl here...");

begin
  GSRn <= '0' when (RST='1' or SUSPn='0') else '1';       -- global reset
  GSR_GSR : GSR port map ( GSR=>GSRn );

  -----------------------------------------------
  -- instantiate the internal osc
  OSCInst0: osch
    -- synthesis translate_off
    generic map ( nom_freq => "2.08" )
    -- synthesis translate_on
    port map ( stdby    => '0',
               osc      => osc,
               sedstdby => open   );    -- for simulation, use stdby_sed sig
  -----------------------------------------------
  -- LED flasher
  process (osc) begin
    if rising_edge(osc) then
      counter <= counter + 1;
    end if;
  end process;
  flash <= counter(counter'high);
  -----------------------------------------------
  -- control via UART
  UCTL : fanuctl port map ( rxd   => utxd,
                            txd   => urxd,
                            xclk  => xclk,
                            XI    => XI,
                            XO    => XO   );
  -----------------------------------------------
  -- control logic
  process (xclk) begin
    if rising_edge(xclk) then
      if XI.PWr then
        case XI.PA is
          when THE_MISC_REG  => miscReg  <= ToInteger(XI.PD);
          when THE_RED_REG   => redReg   <= ToInteger(XI.PD);
          when THE_GREEN_REG => greenReg <= ToInteger(XI.PD);
          when others        => null;
        end case;
      end if;
    end if;
  end process;

  -----------------------------------------------
  -- counters
  process (xclk) begin
    if rising_edge(xclk) then
      redCounter   <= (redCounter + 1)   mod (BRIGHT_MAX + 1);
      greenCounter <= (greenCounter + 1) mod (BRIGHT_MAX + 1);
      redX   <= to_sl(redCounter   <= redReg);
      greenX <= to_sl(greenCounter <= greenReg);
    end if;
  end process;

  -----------------------------------------------
  -- drive the LEDs
  LED_BLOCK : block
  begin
    RedLed   <= '0'       when GSRn='0'                else
                flash     when miscReg=LED_ALTERNATING else
                flash     when miscReg=LED_SYNC        else
                redX      when miscReg=LED_ON          else
                '0';
    GreenLed <= '0'       when GSRn='0'                else
                not flash when miscReg=LED_ALTERNATING else
                flash     when miscReg=LED_SYNC        else
                greenX    when miscReg=LED_ON          else
                '0';
  end block LED_BLOCK;

  -----------------------------------------------
  -- ID and Misc register readback
  process (xclk)
    variable v : integer range 0 to 255;
  begin
    if rising_edge(xclk) then

      if XI.PA = THE_MISC_REG then
        v := miscReg;
      elsif XI.PA = THE_RED_REG then
        v := redReg;
      elsif XI.PA = THE_GREEN_REG then
        v := greenReg;
      else
        v := id(XI.PRdSubA mod 16);
      end if;
      XO <= n2slv(v, 8);

    end if;
  end process;

end rtl;
-- EOF ----------------------------------------------------------------
