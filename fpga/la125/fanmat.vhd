-----------------------------------------------------------------------
-- fanmat.vhd    Bugblat fan logic analyser pattern matcher
--
-- Initial entry: 08-Jan-12 te
--
-- see copyright notice in fandefs.vhd
-----------------------------------------------------------------------
-- Eval with output synchronising register to improve timing
library ieee;           use ieee.std_logic_1164.all;
library work;           use work.utils.all, work.defs.all;

entity TwoLineEval is generic (INIT : slv4 := x"F");
                port  ( ra,
                        wa      : in  slv2;
                        sclk,
                        xclk,
                        din     : in  std_logic;
                        we,
                        invert  : in  boolean;
                        F       : out std_logic := '0' );
end TwoLineEval;

architecture rtl of TwoLineEval is
  attribute syn_hier        : string;
  attribute syn_hier of rtl : architecture is "hard";

  signal mem : slv4 := INIT;

begin
  process (xclk) begin
    if rising_edge(xclk) then
      if we then
        mem(ToInteger(wa)) <= din;
      end if;
    end if;
  end process;

  process (sclk)
    variable v : std_logic;
  begin
    if rising_edge(sclk) then
      v := mem(ToInteger(ra));
      if invert then
        F <= not v;
      else
        F <= v;
      end if;
    end if;
  end process;

end rtl;

--=====================================================================
-- tree-organised pattern matcher, with two levels of 2-bit match circuits
-- delay per level is 1 clocks, so 2 clock delay through the complete tree
--
-- for simplicity, registers are written from incoming data bits 3..0, four
-- bits at a time. Each 4-bit RAM requres 4 writes.
-----------------------------------------------------------------------
library ieee;           use ieee.std_logic_1164.all, ieee.numeric_std.all;
library work;           use work.utils.all, work.defs.all;

entity Matcher is generic ( IX : integer);
  port ( xclk,
         Sclk         : in  std_logic;
         XI           : in  XIrec;
         matcherDin   : in  std_logic;
         matcherWa    : in  unsigned(1 downto 0);
         matcherSubA  : in  TXSubA;
         doLoad       : in  boolean;
         aval,
         bval         : in  TSig;
         matcherOut   : out std_ulogic    );
end Matcher;

architecture rtl of Matcher is
  -------------------------------------------------
  component TwoLineEval is generic (INIT : slv4 := x"F");
                port  ( ra,
                        wa      : in  slv2;
                        sclk,
                        xclk,
                        din     : in  std_logic;
                        we,
                        invert  : in  boolean;
                        F       : out std_logic := '0' );
  end component TwoLineEval;
  -------------------------------------------------
  signal  matchA  : std_logic_vector(TSig'range);
  signal  doAnd   : boolean;

begin

  process (xclk) begin
    if rising_edge(xclk) then
      if XI.PWr and (XI.PA = MATCH_COMBINE_REG) then
        doAnd <= XI.PD(IX) = '1';
      end if;
    end if;
  end process;

  -----------------------------------------------
  -- L0 evals. Delay is 1 clock - each eval is sync'd
  G0: for i in 0 to CHANS -1 generate
    signal we     : boolean;
    signal ra, wa : slv2;       -- read and write addresses
  begin
    we <= doLoad and (matcherSubA = (IX*CHANS + i));
    ra <= bval(i) & aval(i);
    wa <= std_logic_vector(matcherWa);

    SE: TwoLineEval port map (  ra      => ra,
                                wa      => wa,
                                sclk    => sclk,
                                xclk    => xclk,
                                din     => matcherDin,
                                we      => we,
                                invert  => doAnd,         -- inner deMorgan
                                F       => MatchA(i)    );
  end generate G0;

  -----------------------------------------------
  -- L1 eval. Delay is 1 clock
  -- uses de Morgan inversion to implement combining
  -- a and b = not((not a) or (not b))
  -- a  or b =    ((    a) or (    b))
  process (Sclk)
    variable v : std_logic;
  begin
    if rising_edge(Sclk) then
      v := '0';
      for i in MatchA'range loop
        v := v or MatchA(i);
      end loop;

      if doAnd then
        matcherOut <= not v;               -- final de Morgan inversion
      else
        matcherOut <= v;
      end if;

    end if;
  end process;

end rtl;

--=====================================================================
library ieee;           use ieee.std_logic_1164.all, ieee.numeric_std.all;
library work;           use work.utils.all, work.defs.all;

entity fanmatch is
     port ( xclk, sclk  : in    std_logic;
            reset       : in    boolean;
            XI          : in    XIrec;
            samp        : in    TSig;
            sampValid   : in    boolean;
            Match       : out   slv2;
            MatchValid  : out   boolean       );
end fanmatch;

architecture rtl of fanmatch is
  -------------------------------------------------
  component Matcher is generic ( IX : integer);
      port  ( xclk,sclk   : in  std_logic;
              XI          : in  XIrec;
              matcherDin  : in  std_logic;
              matcherWa   : in  unsigned(1 downto 0);
              matcherSubA : in  TXSubA;
              doLoad      : in  boolean;
              aval,bval   : in  TSig;
              matcherOut  : out std_ulogic      );
  end component Matcher;
  -------------------------------------------------
  component TwoLineEval is generic (INIT : slv4 := x"F");
      port  ( ra,
              wa          : in  slv2;
              sclk,
              xclk,
              din         : in  std_logic;
              we,
              invert      : in  boolean;
              F           : out std_logic := '0' );
  end component TwoLineEval;
  -------------------------------------------------
  signal  Match0, Match1  : std_logic;
  signal  SampLast        : TSig;
  signal  SampLastValid   : boolean;         -- resets to false

  constant MATCHER_DELAY  : integer := 3     -- in matchers
                                       +1;   -- in X Evals

  type TMatValidArray is array (MATCHER_DELAY-1 downto 0) of boolean;
  signal MatValid : TMatValidArray;

  signal  matcherDin  : slv4;
  signal  matcherWa   : unsigned(1 downto 0);
  signal  matcherSubA : TXSubA := 0;          -- snapshot of XI.PWrSubA
  signal  doLoad      : boolean;

begin

  LOAD_BLOCK : block
    signal  hitEvals  : boolean;
    type Tstate is ( Sidle, Sshift );
    signal  state : Tstate := Sidle;
  begin
    process (xclk) begin
      if rising_edge(xclk) then
        hitEvals <= (XI.PA = MATCH_EVAL_REG);

        if reset then
          state <= Sidle;
        else
          case state is
            when Sidle =>
              if XI.PWr and hitEvals then
                matcherDin  <= XI.PD(3 downto 0);
                matcherWa   <= (others => '0');
                matcherSubA <= XI.PWrSubA;
                state <= Sshift;
              end if;

            when Sshift =>
              matcherDin(2 downto 0) <= matcherDin(3 downto 1);
              matcherWa <= matcherWa+1;
              if matcherWa = "11" then
                state <= Sidle;
              end if;

          end case;
        end if;

      end if;
    end process;
    doLoad <= (state = Sshift);

  end block LOAD_BLOCK;

---------------------------------------------------------------------
  process (sclk) begin
    if rising_edge(sclk) then
      if reset then
        SampLastValid <= false;
      elsif sampValid then
        SampLast      <= samp;
        SampLastValid <= true;
      end if;
      MatValid <= MatValid(MatValid'high-1 downto 0) &
                                      (sampValid and SampLastValid);
    end if;
  end process;

  -- the pattern matchers
  M0: Matcher  generic map ( IX => 0)
               port map ( xclk        => xclk,
                          sclk        => sclk,
                          XI          => XI,
                          matcherDin  => matcherDin(0),
                          matcherWa   => matcherWa,
                          matcherSubA => matcherSubA,
                          doLoad      => doLoad,
                          aval        => samp,
                          bval        => SampLast,
                          matcherOut  => Match0  );

  M1: Matcher  generic map ( IX => 1)
               port map ( xclk        => xclk,
                          sclk        => sclk,
                          XI          => XI,
                          matcherDin  => matcherDin(0),
                          matcherWa   => matcherWa,
                          matcherSubA => matcherSubA,
                          doLoad      => doLoad,
                          aval        => samp,
                          bval        => SampLast,
                          matcherOut  => Match1  );

  ---------------------------------------------------------------------
  -- the X combiners
  X_BLOCK: block
    constant NUM_X_COMBINERS : integer := 2;
    signal XcomOut : std_logic_vector(NUM_X_COMBINERS-1 downto 0);
    signal ra, wa  : slv2;
  begin
    ra <= Match1 & Match0;
    wa <= std_logic_vector(matcherWa);
    -----------------------------------------------
    -- Delay is 1 clock - each eval is sync'd
    XE: for i in 0 to NUM_X_COMBINERS -1 generate
      signal we   : boolean;
      signal eval : std_logic;
    begin
      we <= doLoad and (matcherSubA = (2*CHANS + i));

      SE: TwoLineEval port map (  ra      => ra,
                                  wa      => wa,
                                  sclk    => sclk,
                                  xclk    => xclk,
                                  din     => matcherDin(0),
                                  we      => we,
                                  invert  => false,
                                  F       => eval     );

      XcomOut(i) <= eval;
    end generate XE;

    Match      <= XcomOut;                    -- out to state machine
    MatchValid <= MatValid(MatValid'high);    -- out to state machine
  end block X_BLOCK;

end rtl;
-----------------------------------------------------------------------
-- eof fanmat.vhd
