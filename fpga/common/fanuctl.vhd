-----------------------------------------------------------------------
-- fanuctl.vhd    Bugblat Fan board U(S)ART control I/O
--
-- Initial entry: 28-Jun-14 te
-- see copyright notice in fandefs.vhd
-------------------------------------------------------------------------
library ieee ;        use ieee.std_logic_1164.all, ieee.numeric_std.all;

entity uartTx is port (
  rst, wr     : in boolean;
  clk8x       : in std_logic;
  din         : in std_logic_vector(7 downto 0);
  done, ready : out boolean;
  txd         : out std_logic   );
end uartTx ;

architecture rtl of uartTx is
  constant  CLK_N     : integer := 8;
  constant  SHIFT_N   : integer := 9;
  signal  clkCount    : integer range 0 to CLK_N-1 := 0;
  signal  lastClk     : boolean;
  signal  rstD1       : boolean;
  signal  shiftReg    : std_logic_vector(SHIFT_N downto 0) := (others=>'1');
  signal  shiftCount  : integer range 0 to SHIFT_N := 0;

  type TSstate is ( Sreset,
                    Sready,
                    Sshift,
                    Sdone          );
  signal state : TSstate;

begin
  lastClk <= (clkCount = (CLK_N-1));

  process (clk8x) begin
    if rising_edge(clk8x) then
      rstD1 <= rst;
      if rst or rstD1 then
        state <= Sreset;
        shiftReg(0) <= '1';
      else
        case state is
          when Sreset =>
            state <= Sready;

          when Sready =>
            shiftCount <= 0;
            clkCount <= 0;
            if wr then
              shiftReg <= '1' & din & '0';
              state    <= Sshift;
            end if;

          when Sshift =>
            clkCount <= (clkCount+1) mod CLK_N;
            if lastClk then
              if shiftCount = SHIFT_N then
                state <= Sdone;
              else
                shiftReg(shiftReg'high-1 downto 0) <= shiftReg(shiftReg'high downto 1);
                shiftCount <= shiftCount+1;
              end if;
            end if;

          when Sdone =>
            state <= Sready;

        end case;
      end if;
    end if;
  end process ;

  ready <= state = Sready;
  done  <= state = Sdone;
  txd   <= shiftReg(0);
end;

-----------------------------------------------------------------------
library ieee ;        use ieee.std_logic_1164.all ;
                      use ieee.numeric_std.all ;

entity uartRx is port (
  rst         : in boolean;
  clk8x, rxd  : in std_logic;
  dout        : out std_logic_vector(7 downto 0);
  ready       : out boolean     );
end uartRx ;

architecture rtl of uartRx is

  constant  CLK_N     : integer := 8;
  constant  SHIFT_N   : integer := 8;
  signal  clkCount    : integer range 0 to CLK_N-1 := 0;
  signal  clk4, clk7,
          lastClk     : boolean;
  signal  rxdD1       : std_logic := '0';
  signal  start       : boolean;
  signal  rstD1       : boolean;
  signal  shiftReg    : std_logic_vector(SHIFT_N-1 downto 0) := (others=>'0');
  signal  shiftCount  : integer range 0 to SHIFT_N := 0;

  type TSstate is ( Sidle,
                    Sstart,
                    Sshift,
                    Sdone          );
  signal state : TSstate;

begin
  clk4    <= clkCount = 4;
  clk7    <= clkCount = (CLK_N-1);
  lastClk <= clk4 when (shiftCount > 7)     -- cut short the stop bit
                  else clk7;
  start <= (rxd='0') and (rxdD1='1');

  process (clk8x)
    variable ce : boolean;
  begin
    if rising_edge(clk8x) then
      rstD1 <= rst;
      rxdD1 <= rxd;
      if rst or rstD1 then
        state <= Sidle;
      else
        case state is
          when Sidle =>
            shiftCount <= 0;
            clkCount <= 0;
            if start then
              state <= Sstart;
            end if;

          when Sstart =>
            if clk4 then
              clkCount <= 0;
              state <= Sshift;
            else
             clkCount <= (clkCount+1) mod CLK_N;
            end if;

          when Sshift =>
            clkCount <= (clkCount+1) mod CLK_N;
            if lastClk then
              if shiftCount=SHIFT_N then
                state <= Sdone;
                dout <= shiftReg(shiftReg'high downto 0);
              else
                shiftReg <= rxd & shiftReg(shiftReg'high downto 1);
                shiftCount <= shiftCount+1;
              end if;
            end if;

          when Sdone =>
            state <= Sidle;

        end case;
      end if;


    end if;
  end process;

  ready <= state = Sdone;

end ;

---------------------------------------------------------------------
library IEEE;               use IEEE.std_logic_1164.all;
                            use IEEE.numeric_std.all;
library work;               use work.utils.all, work.defs.all;
                            use work.attributes.all;
library machxo2;            use machxo2.components.all;

entity fanuctl is port (
    rxd         : in    std_logic;
    txd         : out   std_logic;
    xclk        : in    std_logic;
    XI          : out   XIrec;
    XO          : in    slv8       );
end fanuctl;

architecture rtl of fanuctl is
  ---------------------------------------------
  component uartTx is port (
    rst, wr     : in boolean;
    clk8x       : in std_logic;
    din         : in std_logic_vector(7 downto 0);
    done, ready : out boolean;
    txd         : out std_logic   );
  end component uartTx ;
  ---------------------------------------------
  component uartRx is port (
    rst         : in boolean;
    clk8x, rxd  : in std_logic;
    dout        : out std_logic_vector(7 downto 0);
    ready       : out boolean     );
  end component uartRx ;
  ---------------------------------------------

  signal  rxData    : slv8;
  signal  byteType  : slv2;           -- bits 7..6 bits of incoming byte
  signal  inData    : slv6;           -- bits 5..0 bits of incoming byte
  signal  rdSubAddr
        , wrSubAddr : TXSubA  := 0;   -- sub-addresses
  constant MAX_READ : natural := 512; -- could be 64. FT230 FIFO is 512 bytes
  signal  count     : integer range 0 to (MAX_READ-1) := 0;

  constant HOLDOFF     : natural := 7;
  signal   holdCounter : natural range 0 to HOLDOFF;

  signal  countZero
--      , hitCount
        , rxReady
        , txWr
        , txDone
        , txReady   : boolean;
  signal  XiLoc     : XIrec;          -- local copy of XI

  type Tstate is ( sIdle,
                   sWr1, sWr2, sWr3,
                   sRd1, sRd2, sRd3, sRd2RdDelay, sRd2RdCountdown,
                   sTurn );
  signal  state : Tstate;

  signal  uartReset : boolean := true;

begin
  ---------------------------------------------------------------------
  -- Power-Up Reset for a few clocks
  -- assumes initialisers are honoured by the synthesiser
  RST_BLK: block
    constant COUNTER_MAX : integer := 7;
    signal rstCount      : integer range 0 to COUNTER_MAX := 0;
  begin
    process (xclk) begin
      if rising_edge(xclk) then
        if rstCount /= COUNTER_MAX then
          rstCount <= rstCount +1;
        end if;
        uartReset <= (rstCount /= COUNTER_MAX);
      end if;
    end process;
  end block RST_BLK;

  -----------------------------------------------
  RX: uartRx port map (
    rst     => uartReset,
    clk8x   => xclk,
    rxd     => rxd,
    dout    => rxData,
    ready   => rxReady      );

  TX: uartTx port map (
    rst     => uartReset,
    wr      => txWr,
    clk8x   => xclk,
    din     => XO,
    done    => txDone,
    ready   => txReady,
    txd     => txd          );
  -----------------------------------------------

  -- extract the type field from the incoming data byte
  byteType  <= rxData(7 downto 6);
  inData    <= rxData(5 downto 0);
  countZero <= (count = 0);
--hitCount  <= (XiLoc.PA = W_COUNT_REG);

  process(xclk)
  begin
    if rising_edge(xclk) then
      if uartReset then
        count <= 0;
        state <= sIdle;
        rdSubAddr <= 0;
        wrSubAddr <= 0;
      else
        case state is
          when sIdle =>
            if rxReady then
              case byteType is
                when A_ADDR =>
                  XiLoc.PA <= toInteger(inData);
                  rdSubAddr <= 0;
                  wrSubAddr <= 0;
                  state <= sTurn;
                when D_ADDR =>
                  XiLoc.PD <= inData;
                  state <= sWr1;
                when T_ADDR =>                    -- write 'count' register
                  count <= (count*64 + toInteger(inData)) mod MAX_READ;
  --              count <= toInteger(inData) mod MAX_READ;
                  state <= sRd2RdDelay;           -- and read
                when H_ADDR =>                    -- write 'count' register
                  count <= (count*64 + toInteger(inData)) mod MAX_READ;
                  state <= sTurn;                 -- but don't read
                when others =>                    -- never get here
                  state <= sTurn;
              end case;
            end if;

          -------------------------------------------------------------
          -- write logic
          when sWr1 =>
            state <= sWr2;

          when sWr2 =>
            state <= sWr3;

          when sWr3 =>
            wrSubAddr <= (wrSubAddr+1) mod (XSUBA_MAX+1);
            state <= sTurn;

          -------------------------------------------------------------
          -- read logic
          when sRd2RdDelay =>
            holdCounter <= HOLDOFF;
            state <= sRd2RdCountdown;

          when sRd2RdCountdown =>
            if (holdCounter = 0) then
              state <= sRd1;
            else
              holdCounter <= holdCounter-1;
            end if;

          when sRd1 =>
            if txReady then
              count <= (count + MAX_READ -1) mod MAX_READ;    -- i.e. -1
              state <= sRd2;
            end if;

          when sRd2 =>
            rdSubAddr <= (rdSubAddr+1) mod (XSUBA_MAX+1);
            state <= sRd3;

          when sRd3 =>
            if txDone then
              if countZero then
                state <= sTurn;
              else
                state <= sRd2RdDelay;
              end if;
            end if;

          -------------------------------------------------------------
          -- turn-round state(s)
          when sTurn =>
            state <= sIdle;

        end case;

        txWr <= (state = sRd2);               -- txReady and (state=sRd1);
        XiLoc.PWr <= (state=sWr1);
        XiLoc.PRdFinished <= txWr;
      end if;

    end if;
  end process;

--XiLoc.PRd     <= (state=sRd1);
  XiLoc.PRdSubA <= rdSubAddr;
  XiLoc.PWrSubA <= wrSubAddr;
  XI <= XiLoc;

end rtl;

-----------------------------------------------------------------------
-- EOF fanuctl.vhd
