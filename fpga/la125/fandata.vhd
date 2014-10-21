-----------------------------------------------------------------------
-- fandata.vhd    Bugblat fan logic analyser data path
--
-- Initial entry: 05-Jan-12 te
--
-- see copyright notice in fandefs.vhd
-----------------------------------------------------------------------
library ieee;           use ieee.std_logic_1164.all, IEEE.numeric_std.all;
library work;           use work.utils.all, work.defs.all;
library machxo2;        use machxo2.components.all;

entity fandata is
     port ( xclk, sclk  : in    std_logic;
            CtlRec      : in    TCtlRec;
            samp        : in    TSig;
            sampValid   : in    boolean;
            TrigFlag,
            DoneFlag    : in    boolean;
            WEFlag      : out   boolean;
            XI          : in    XIrec;
            XO          : out   slv8
            );
end fandata;

architecture rtl of fandata is
  -----------------------------------------------
  component fanbram is
    port  ( xclk, sclk  : in  std_logic;
            wrAddr      : in  TBramWrAddr;
            wrData      : in  TBramWrData;
            wrEna,
            reset       : in  boolean;
            XI          : in  XIrec;
            XO          : out slv8      );
  end component fanbram;
  -----------------------------------------------

  signal  sampD1,
          sampD2        : TSig;
  signal  sampD1Changed,
          sampValidD1   : boolean;

  signal  trigPoint     : unsigned(TBramWrAddr'range);
  signal  finalWrAddr   : unsigned(TBramWrAddr'range);
  signal  ramFilled     : boolean;
  signal  XOram         : slv8 := (others=>'0');

  alias   reset         : boolean   is CtlRec.Reset;
  alias   run           : boolean   is CtlRec.Run;

  constant COUNT_BITS   : integer := 10;
  signal  count         : unsigned(COUNT_BITS-1 downto 0);
  -- one less than the maximum count
  constant MAX_COUNT_1  : unsigned(count'range) := (0=>'0', others=>'1');
  signal  countMax      : boolean;

  type Tstate is ( Sidle, Sfirst, Scompare, Slast, Sdone );
  signal  state         : Tstate;

  -- extra address bit so that we can detect rollover for ramFilled
  signal  ramWA         : unsigned(TBramWrAddr'high+1 downto 0);
  signal  ramDI         : slv18;
  signal  ramWE         : boolean;

begin

  process (sclk)
    variable we_var : boolean;
  begin
    if rising_edge(sclk) then

      we_var := false;

      if reset then
        trigPoint   <= (others => '0');
        ramWA       <= (others => '0');
        finalWrAddr <= (others => '0');
        ramFilled   <= false;

        count <= (others=>'0');
        countMax <= false;

        sampValidD1 <= false;

        state <= Sidle;
      else

        if sampValid then
          sampD1 <= samp;
          sampD2 <= sampD1;
        end if;
        sampValidD1   <= sampValid;
        sampD1Changed <= (samp /= sampD1);

        case state is
          when Sidle =>
            if run then
              state <= Sfirst;
            end if;

          when Sfirst =>
            if sampValidD1 then
              state <= Scompare;
            end if;

          when Scompare =>
            if sampValidD1 then
              if sampD1Changed or countMax then
                count    <= (others=>'0');
                countMax <= false;
                we_var   := true;
              else
                count    <= count+1;
                countMax <= count = MAX_COUNT_1;
              end if;
            end if;

            if DoneFlag then
              state <= Slast;
            end if;

          when Slast =>
            we_var := true;
            state  <= Sdone;

          when Sdone =>     -- wait for reset
            null;

        end case;

        if (ramWA(ramWA'high) = '1') then
          ramFilled <= true;
        end if;
      end if;

      ramWE <= we_var;
      if we_var then
        ramDI <= std_logic_vector(count) & sampD2;
      end if;

      if ramWE then
        finalWrAddr <= ramWA(finalWrAddr'range);
        ramWA       <= ramWA+1;
      end if;

      if TrigFlag then
        trigPoint <= ramWA(trigPoint'range);
      end if;

    end if;
  end process;

  -------------------------------------------------
  RAM_INST: fanbram port map (
                    sclk    =>  sclk,
                    xclk    =>  xclk,
                    wrAddr  =>  std_logic_vector(ramWA(TBramWrAddr'range)),
                    wrData  =>  ramDI,
                    wrEna   =>  ramWE,
                    reset   =>  reset,
                    XI      =>  XI,
                    XO      =>  XOram    );

  WEFlag <= ramWE;

  ---------------------------------------------------------------------
  -- status (sub)register readback
  READBACK_BLK: block
    signal  XOreg : slv8;
  begin
    process (xclk)
      variable  finalWA, trigA : slv32;
      variable  reg : slv8;
    begin
      if rising_edge(xclk) then
        finalWA                     := (others => '0');
        finalWA(finalWrAddr'range)  := std_logic_vector(finalWrAddr);
        trigA                       := (others => '0');
        trigA(trigPoint'range)      := std_logic_vector(trigPoint);

        reg := (others=>'0');

        if XI.PA = STATUS_REG then
          case XI.PRdSubA mod STATUS_REG_NUM_SUBS is
            when STATUS_REG_STATUS =>
              reg := (STATUS_RAMWRITTEN => to_sl(ramFilled), others => '0');

            when STATUS_REG_TRIG_BYTE_0   =>  reg := trigA(BYTE_0);
            when STATUS_REG_TRIG_BYTE_1   =>  reg := trigA(BYTE_1);
            when STATUS_REG_TRIG_BYTE_2   =>  reg := trigA(BYTE_2);
            when STATUS_REG_TRIG_BYTE_3   =>  reg := trigA(BYTE_3);

            when STATUS_REG_RAMA_BYTE_0   =>  reg := finalWA(BYTE_0);
            when STATUS_REG_RAMA_BYTE_1   =>  reg := finalWA(BYTE_1);
            when STATUS_REG_RAMA_BYTE_2   =>  reg := finalWA(BYTE_2);
            when STATUS_REG_RAMA_BYTE_3   =>  reg := finalWA(BYTE_3);

            when others =>  null;
          end case;
        end if;
        XOreg <= reg;

      end if;
    end process;

   XO <= XOreg or XOram;

  end block READBACK_BLK;

end rtl;
-- EOF fandata.vhd
