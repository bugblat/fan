-----------------------------------------------------------------------
-- fansm.vhd    Bugblat fan logic analyser central state machine
--
-- Initial entry: 06-Jan-12 te
--
-- see copyright notice in fandefs.vhd
-----------------------------------------------------------------------
library ieee;                 use ieee.std_logic_1164.all;
library work;                 use work.attributes.all;
                              use work.utils.all;
                              use work.defs.all;

entity FourLineEval is generic (INIT : slv16 := x"FFFF");
                port  ( ra,
                        wa      : in  slv4;
                        sclk,
                        xclk,
                        din     : in  std_logic;
                        we      : in  boolean;
                        F       : out std_logic := '0' );
end FourLineEval;

architecture rtl of FourLineEval is
  attribute syn_hier of rtl: architecture is "hard";

  signal mem : slv16 := INIT;

begin
  process (xclk) begin
    if rising_edge(xclk) then
      if we then
        mem(ToInteger(wa)) <= din;
      end if;
    end if;
  end process;

  process (sclk) begin
    if rising_edge(sclk) then
      F <= mem(ToInteger(ra));
    end if;
  end process;

end rtl;

-----------------------------------------------------------------------
library IEEE;                 use IEEE.std_logic_1164.all;
                              use IEEE.numeric_std.all;

library work;                 use work.utils.all;
                              use work.attributes.all;
                              use work.defs.all;

library machxo2;              use machxo2.components.all;

entity fansm is
  port (
    ClkRec      : in    TClkRec;
    CtlRec      : in    TCtlRec;
    sigIn       : in    Tsig;
    extraHit    : in    boolean;
    XI          : in    XIrec;
    XO          : out   slv8;
    trigOut,
    RedLed,
    GreenLed    : out   std_logic    );
end fansm;

architecture rtl of fansm is
  ------------------------------------------
  component activity is
    port (
      xclk        : in    std_logic;
      sclk        : in    std_logic;
      sig         : in    TSig;
      XI          : in    XIrec;
      XO          : out   slv8          );
  end component activity;
  ------------------------------------------
  component simpleFlasher is
    port ( red, green : out std_logic );
  end component simpleFlasher;
  ------------------------------------------
  component triggerOut is
    port (
      sclk,
      xclk        : in    std_logic;
      XI          : in    XIrec;
      triggered   : in    boolean;
      trigOut     : out   std_logic     );
  end component triggerOut;
  ------------------------------------------
  component fandata is
    port (
      xclk, sclk  : in    std_logic;
      CtlRec      : in    TCtlRec;
      samp        : in    TSig;
      sampValid   : in    boolean;
      TrigFlag,
      DoneFlag    : in    boolean;
      WEFlag      : out   boolean;
      XI          : in    XIrec;
      XO          : out   slv8          );
  end component fandata;
  ------------------------------------------
  component FourLineEval is
    generic (INIT : slv16 := x"FFFF");
    port  (
      ra,
      wa          : in    slv4;
      sclk,
      xclk,
      din         : in    std_logic;
      we          : in    boolean;
      F           : out   std_logic := '0' );
  end component FourLineEval;
  ------------------------------------------
  component downCounter is generic ( BITS : integer := 10);
    port (
      Clk         : in    std_logic;
      InitialVal  : in    unsigned(BITS-1 downto 0);
      LoadN,
      CE          : in    std_logic;
      zero        : out   boolean       );
  end component downCounter;
  ------------------------------------------
  component fanmatch is
    port (
      xclk, sclk  : in    std_logic;
      reset       : in    boolean;
      XI          : in    XIrec;
      samp        : in    TSig;
      sampValid   : in    boolean;
      Match       : out   slv2;
      MatchValid  : out   boolean       );
  end component fanmatch;
  ------------------------------------------

  type TLAstate is (
         LAidle,
         LAprefill,
         LAsearch,
         LAEnterHit1,
         LAhit1,
         LAEnterHit2,
         LAhit2,
         LAtriggered,
         LAdone );
  signal LAstate : TLAstate;

  signal TcZero,        -- timer counter decremented to zero
                        -- logic matches trigering the state machine
         SearchHit1, SearchTrig,
         Hit1Hit2,   Hit1Trig,
         Hit2Hit1,   Hit2Trig,
         InIdle,
         InHit1,EnteredHit1,
         InHit2,EnteredHit2,
         InTriggered,
         TCena,         -- timer/counter enable and load
         TCload  : std_logic := '0';

  -- speeds simulation if these have low defaults
  constant PRECOUNT_INIT  : integer :=  100;
  constant POSTCOUNT_INIT : integer :=  100;
  constant TIMER_CTR_INIT : integer :=    5;

  -- timer-counter regs
  constant TCTR_INIT : unsigned(TC_BITS-1 downto 0) :=
                                        to_unsigned(TIMER_CTR_INIT, TC_BITS );
  signal  TCtrReg   : unsigned(TC_BITS-1 downto 0) := TCTR_INIT;

  -- Pre/Post regs to hold the Pre/PostCount values between runs
  constant PRE_INIT  : unsigned (TBramWrAddr'range) :=
                                    to_unsigned(PRECOUNT_INIT,  BRAM_WA_BITS);
  constant POST_INIT : unsigned (TBramWrAddr'range) :=
                                    to_unsigned(POSTCOUNT_INIT, BRAM_WA_BITS);
  signal PreCountReg : unsigned (TBramWrAddr'range) := PRE_INIT;
  signal PostCountReg: unsigned (TBramWrAddr'range) := POST_INIT;

  -- state machine transitions when counters decrement to zero
  signal PreCountZero,
         PostCountZero: boolean;

  signal Triggered,                 -- eventually true unless the LA is stopped
         TrigFlag,                  -- true for one cycle
         DoneFlag,                  -- true for one cycle
         WEFlag                     -- from the lower-level RAM write
                      : boolean;
  signal ValidD1      : std_logic;

  signal HaltNow      : boolean;    -- decoded Ctl.Stop && (LAstate /= LAidle)
                                    --  helps to meet timing at 125MHz
  signal ResetDlyA    : boolean;    -- delayed Ctl.Reset, to help timing
  attribute syn_preserve of ResetDlyA: signal is true;

  signal  XOdata,
          XOact       : slv8;

  alias   sclk        : std_logic is ClkRec.Sclk;
  alias   xclk        : std_logic is ClkRec.xclk;

  signal  red_flash,
          green_flash : std_logic;

  signal  match       : slv2;
  signal  matchValid  : boolean;

  signal  samp        : TSig;
  constant sampValid : boolean := true;
begin
  ---------------------------------------------------------------------
  -- instantiate the sample logic
  -- this is where you can put more complex sampling logic
  process (sclk) begin
    if rising_edge(sclk) then
      samp <= sigIn;
    end if;
  end process;
  ---------------------------------------------------------------------
  -- instantiate the pin activity monitor
  ACTIVITY_MONITOR : activity
                    port map (  xclk      => xclk,
                                sclk      => sclk,
                                sig       => samp,
                                XI        => XI,
                                XO        => XOact          );
  ---------------------------------------------------------------------
  -- instantiate the LED flashers
  LED: simpleFlasher port map ( red       => red_flash,
                                green     => green_flash    );
  ---------------------------------------------------------------------
  -- instantiate the matcher
  MATCHER: fanmatch port map (  xclk      => xclk,
                                sclk      => sclk,
                                samp      => samp,
                                XI        => XI,
                                reset     => CtlRec.Reset,
                                sampValid => sampValid,
                                Match     => match,
                                MatchValid => matchValid    );
  ---------------------------------------------------------------------
  -- instantiate the data path
  DATA_PATH: fandata port map ( xclk      => xclk,
                                sclk      => sclk,
                                CtlRec    => CtlRec,
                                samp      => samp,
                                sampValid => sampValid,
                                TrigFlag  => TrigFlag,
                                DoneFlag  => DoneFlag,
                                WEFlag    => WEFlag,
                                XI        => XI,
                                XO        => XOdata         );
  ---------------------------------------------------------------------

    process (sclk) begin
      if rising_edge(sclk) then
        ValidD1 <= to_sl(matchValid);
      end if;
    end process;
  ---------------------------------------------------------------------
  -- evaluate the flags which drive the state machine via lookups
  -- into a bank of loadable 16-bit ROMs
  ROMs: block
    signal SearchTest,      -- 4-bit addresses for the ROM evaluations
           HitTest,
           TCtest         : slv4;
    signal SearchHit1_O,    -- SRL outputs
           SearchTrig_O,
           Hit1Hit2_O,
           Hit1Trig_O,
           Hit2Hit1_O,
           Hit2Trig_O,
           TCena_O,
           TCload_O       : std_logic;

    signal  evalDin  : slv4;
    signal  evalWa   : slv4;
    signal  evalSubA : TXSubA := 0;     -- snapshot of XI.PWrSubA
    signal  doLoad   : boolean;

  begin

    LOADER : block
      signal  hitEvals  : boolean;
      type Tstate is ( Sidle, Sshift );
      signal  state    : Tstate := Sidle;
      signal  evalWaLo : unsigned(1 downto 0);
    begin
      process (xclk) begin
        if rising_edge(xclk) then
          hitEvals <= XI.PA = SM_EVAL_REG;

          if CtlRec.Reset then
            state <= Sidle;
          else
            case state is
              when Sidle =>
                if XI.PWr and hitEvals then
                  evalDin  <= XI.PD(3 downto 0);
                  evalWaLo <= (others => '0');
                  evalSubA <= XI.PWrSubA;
                  state <= Sshift;
                end if;

              when Sshift =>
                evalDin(2 downto 0) <= evalDin(3 downto 1);
                evalWaLo <= evalWaLo+1;
                if evalWaLo = "11" then
                  state <= Sidle;
                end if;

            end case;
          end if;

        end if;
      end process;
      doLoad <= (state = Sshift);
      evalWa(3 downto 2) <= n2slv2(evalSubA);
      evalWa(1 downto 0) <= std_logic_vector(evalWaLo);

    end block LOADER;

    -- state machine evals. Delay is 1 clock - each eval is sync'd
    -----------------------------------------------
    EVALS: block
      constant NUM_EVALS : natural := 8;
      type Tra is array (0 to NUM_EVALS-1) of slv4;
      signal ra : Tra;
      signal ev : std_logic_vector(0 to NUM_EVALS-1);
    begin
      -- inputs to the evaluation ROMs
      ra(0) <= "11" & match;                                -- SearchTrig
      ra(1) <= "11" & match;                                -- SearchHit1
      ra(2) <= '1' & TcZero & match;                        -- Hit1Trig
      ra(3) <= '1' & TcZero & match;                        -- Hit1Hit2
      ra(4) <= '1' & TcZero & match;                        -- Hit2Trig
      ra(5) <= '1' & TcZero & match;                        -- Hit2Hit1
      ra(6) <= EnteredHit2 & EnteredHit1 & InHit2 & InHit1; -- TCload
      ra(7) <= EnteredHit2 & EnteredHit1 & InHit2 & InHit1; -- TCena

      GEVAL: for i in 0 to NUM_EVALS-1 generate
        signal we : boolean;
      begin
        we <= doLoad and ((evalSubA/4) = i);

        SE: FourLineEval port map ( ra      => ra(i),
                                    wa      => evalWa,
                                    sclk    => sclk,
                                    xclk    => xclk,
                                    din     => evalDin(0),
                                    we      => we,
                                    F       => ev(i)       );
      end generate GEVAL;

      -- outputs from the evaluation ROMs
      SearchTrig <= ev(0) and ValidD1;
      SearchHit1 <= ev(1) and ValidD1;
      Hit1Trig   <= ev(2) and ValidD1;
      Hit1Hit2   <= ev(3) and ValidD1;
      Hit2Trig   <= ev(4) and ValidD1;
      Hit2Hit1   <= ev(5) and ValidD1;
      TCload     <= ev(6) and ValidD1;
      TCena      <= ev(7) and ValidD1;
    end block EVALS;

  end block ROMs;

  ---------------------------------------------------------------------
  -- load the pre/post count and Timer Init quasi-static registers
  process (xclk)
    variable TRdata: unsigned(XI.PD'range); -- copy of XI.PD

    -- ranges for the left of the assignment, pre/post
    subtype pp_al is integer range  5 downto  0;
    subtype pp_bl is integer range PreCountReg'left downto 6;
    -- ranges for the right of the assignment, pre/post
    subtype pp_ar is integer range  5 downto  0;
    subtype pp_br is integer range  PreCountReg'left-6 downto 0;

    -- ranges for the left of the assignment, timer
    subtype tc_al is integer range  5 downto  0;
    subtype tc_bl is integer range TCtrReg'left downto 6;
    -- ranges for the right of the assignment, timer
    subtype tc_ar is integer range  5 downto  0;
    subtype tc_br is integer range  TCtrReg'left-6 downto 0;
  begin

    if rising_edge(xclk) then
      if (XI.PA=COUNTER_TIMER_REG) and XI.PWr then
        TRdata := unsigned(XI.PD);
        case (XI.PWrSubA mod 8) is

          when 0 =>  PreCountReg(pp_al)  <= TRdata(pp_ar);
          when 1 =>  PreCountReg(pp_bl)  <= TRdata(pp_br);

          when 2 =>  PostCountReg(pp_al) <= TRdata(pp_ar);
          when 3 =>  PostCountReg(pp_bl) <= TRdata(pp_br);

          when 4 =>  TCtrReg(tc_al)      <= TRdata(tc_ar);
          when 5 =>  TCtrReg(tc_bl)      <= TRdata(tc_br);

          when others => null;

        end case;
      end if;
    end if;

  end process;

  ---------------------------------------------------------------------
  -- build the timer/counter
  -- Should have TcZero go true as soon as a zero is in the LUTs - load 0
  -- via TCtrReg and TcZero is '1' immediately
  TC: block
    constant r: integer := TCtrReg'length;
    signal TCtr      : unsigned(r downto 0) := (others=>'0');
    signal TimerZero : std_logic;
  begin

    process (sclk)
    begin
      if rising_edge(sclk) then
        if TCload='1' or InIdle='1' then
          TCtr <= '0' & TCtrReg;
        elsif TCena='1' then
          TCtr <= TCtr-1;
        end if;

        -- because the timer/counter is pipelined, we must ignore
        -- a zero which comes in the first cycle after a state change.
        -- without this we get a false trigger on a quick flip from
        -- state to state thus:
        -- state      |  hit 1    |   hit 2   |   hit 1   |   hit 1   |
        -- sclk      _/~~~~~\_____/~~~~~\_____/~~~~~\_____/~~~~~\_____/
        -- count      |    0      |     -1    |    8      |     7     |
        -- TimerZero  |    F      |     T     |    F      |     F     |
        -- TcZero     |    F      |     T     |    F      |     F     |
        -- Hit1Trig   |    F      |     F     |   T!!!!   |     F     |
        --
        -- if we ignore the first cycle we get this:
        -- state      |  hit 1    |   hit 2   |   hit 1   |   hit 1   |
        -- sclk      _/~~~~~\_____/~~~~~\_____/~~~~~\_____/~~~~~\_____/
        -- count      |    0      |     -1    |     8     |     7     |
        -- TimerZero  |    F      |     T     |     F     |     F     |
        -- AllowTimer |    T      |     F     |     F     |     T     |
        -- TCzero     |    F      |     T     |     F     |     F     |
        -- Hit1Trig   |    F      |     F     |     F     |     F     |
        --
        -- note that this effect is NOT caused by our using -1 as the 'zero'

      end if;
    end process;
    TimerZero <= std_logic(TCtr(r));
    TcZero    <= TimerZero;         -- and AllowTimer;
  end block TC;

  ---------------------------------------------------------------------
  -- pre/post counters
  PP: block
    constant r: integer := PreCountReg'length;
    signal LoadLo,
           PreCE,
           PostCE   : std_logic;
  begin
    process (sclk) begin
      if rising_edge(sclk) then
        -- the counters will be two cycles off because the load and CE
        -- signals are pipelined.  This doesn't matter because we are only
        -- filling the pre-search buffer.
        LoadLo <= not InIdle;          -- should get an optimal counter
        PreCE  <= InIdle or to_sl(WEFlag);
        PostCE <= InIdle or (to_sl(WEFlag) and InTriggered);
      end if;
    end process;

    PRE: downCounter generic map ( BITS => PreCountReg'length )
                     port map    ( Clk        => sclk,
                                   InitialVal => PreCountReg,
                                   LoadN      => LoadLo,
                                   CE         => PreCE,
                                   zero       => PreCountZero );

    POS: downCounter generic map ( BITS => PostCountReg'length )
                     port map    ( Clk        => sclk,
                                   InitialVal => PostCountReg,
                                   LoadN      => LoadLo,
                                   CE         => PostCE,
                                   zero       => PostCountZero );

  end block PP;

  ---------------------------------------------------------------------
  -- main LA state machine
  process (sclk)
    variable NextState : TLAstate;
  begin
    if rising_edge(sclk) then

      HaltNow <= CtlRec.Stop and (LAstate /= LAidle);  -- pipeline this decode
      ResetDlyA <= CtlRec.Reset;                       -- local duplicate

      if ResetDlyA then
        NextState := LAidle;
      elsif HaltNow then
        NextState := LAdone;
      else
        NextState := LAstate;
        case LAstate is
          when LAidle   =>
            Triggered <= false;
            if CtlRec.Run then
              NextState := LAprefill;
            end if;

          when LAprefill =>
            if PreCountZero then
              NextState := LAsearch;
            end if;

          when LAsearch  =>
            if extraHit then
              NextState := LAtriggered;
            elsif SearchTrig='1' then
              NextState := LAtriggered;
            elsif SearchHit1='1' then
              NextState := LAEnterHit1;
            end if;

          when LAEnterHit1   =>
            if extraHit then
              NextState := LAtriggered;
            elsif ValidD1 = '1' then
              NextState := LAhit1;
            end if;

          when LAhit1        =>
            if extraHit then
              NextState := LAtriggered;
            elsif Hit1Trig='1' then
              NextState := LAtriggered;
            elsif Hit1Hit2='1' then
              NextState := LAEnterHit2;
            end if;

          when LAEnterHit2   =>
            if extraHit then
              NextState := LAtriggered;
            elsif ValidD1 = '1' then
              NextState := LAhit2;
            end if;

          when LAhit2        =>
            if extraHit then
              NextState := LAtriggered;
            elsif Hit2Trig='1' then
              NextState := LAtriggered;
            elsif Hit2Hit1='1' then
              NextState := LAEnterHit1;
            end if;

          when LAtriggered =>
            Triggered <= true;
            if PostCountZero then
              NextState := LAdone;
            end if;

          when LAdone =>        -- leaves here when CtlRec.Reset
            null;
          when others =>        -- sim likes this
            null;
        end case;
      end if;
      LAstate <= NextState;

    --InPrefill   <=     to_sl(NextState=LAprefill   );
      InIdle      <=     to_sl(NextState=LAidle      );
    --InSearch    <=     to_sl(NextState=LAsearch    );
      InHit1      <=     to_sl(NextState=LAhit1      );
      InHit2      <=     to_sl(NextState=LAhit2      );
      InTriggered <=     to_sl(NextState=LAtriggered );
      EnteredHit1 <=     to_sl(  LAstate=LAEnterHit1 );
      EnteredHit2 <=     to_sl(  LAstate=LAEnterHit2 );

      TrigFlag    <= (NextState=LAtriggered) and (LAstate/=LAtriggered);
      DoneFlag    <= (NextState=LAdone) and (LAstate/=LAdone);

    end if;
  end process;

  ---------------------------------------------------------------------
  -- drive the LEDs
  LEDS: block
    signal Red   : std_logic := '0';    -- reset to low (i.e. off)
    signal Green : std_logic := '0';
  begin
    -- makes the timing checks easier.  This Flop can go anywhere near the
    -- LAstate logic.  A second flop (FD) goes in the IOB
    process (xclk) begin
      if rising_edge(xclk) then
        case LAstate is
          when LAidle       => Red <= red_flash; Green <= green_flash;
          when LAprefill    => Red <= '0';       Green <= green_flash;
          when LAsearch     => Red <= '1';       Green <= '1';
          when LAEnterHit1  => Red <= '0';       Green <= '1';
          when LAhit1       => Red <= '0';       Green <= '1';
          when LAEnterHit2  => Red <= '1';       Green <= '0';
          when LAhit2       => Red <= '1';       Green <= '0';
          when LAtriggered  => Red <= red_flash; Green <= '0';
          when LAdone       => Red <= red_flash; Green <= red_flash;
        end case;
      end if;
    end process;
    RedLed   <= Red;
    GreenLed <= Green;
  end block LEDS;

  ---------------------------------------------------------------------
  TOX: triggerOut port map ( sclk      => sclk,
                             xclk      => xclk,
                             XI        => XI,
                             triggered => TrigFlag,
                             trigOut   => trigOut    );

  ---------------------------------------------------------------------
  -- register readback
  READBACK: block
    signal StateIX  : integer range 0 to 7;
    signal XOstate  : slv8;
  begin
    process (sclk) begin
      if rising_edge(sclk) then
        case LAstate is   -- report state to controlling PC
          when LAidle      =>   StateIX <= LAidleIX;
          when LAprefill   =>   StateIX <= LAprefillIX;
          when LAsearch    =>   StateIX <= LAsearchIX;

          when LAEnterHit1 =>   StateIX <= LAhit1IX;
          when LAhit1      =>   StateIX <= LAhit1IX;

          when LAEnterHit2 =>   StateIX <= LAhit2IX;
          when LAHit2      =>   StateIX <= LAhit2IX;

          when LAtriggered =>   StateIX <= LAtriggeredIX;
          when LAdone      =>   StateIX <= LAdoneIX;
--        when others      =>   StateIX <= LAnonsense;    -- never get here!
        end case;
      end if;
    end process;


    process (xclk) begin
      if rising_edge(xclk) then
        if XI.PA = STATUS_REG then
          case XI.PRdSubA mod STATUS_REG_NUM_SUBS is
            when STATUS_REG_STATUS =>
              XOstate <= to_sl(Triggered) & '0' & n2slv(StateIx, 6);
            when others =>
              XOstate <= (others=>'0');
          end case;
        else
          XOstate <= (others=>'0');
        end if;
      end if;
    end process;

    XO <= XOstate or XOdata or XOact;
  end block READBACK;

end rtl;
-- EOF fansm.vhd
