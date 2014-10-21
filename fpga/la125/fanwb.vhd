-----------------------------------------------------------------------
-- fanwb.vhd    Bugblat fan central Wishbone/control logic
--
-- Initial entry: 05-Jan-12 te
-- see copyright notice in fandefs.vhd
-----------------------------------------------------------------------
library ieee;           use ieee.std_logic_1164.all;
                        use ieee.numeric_std.all;
library work;           use work.defs.all;
                        use work.utils.all;
library machxo2;        use machxo2.components.all;

entity fanwb is
  port (
    xclk        : in    std_logic;
    XI          : in    XIrec;
    XO          : out   slv8;
    refPWM      : out   std_logic;
    wb2pll      : out   Twishbone2pll;
    pll2wb      : in    Tpll2wishbone;
    ctlReset    : in    boolean         );
end fanwb;

architecture rtl of fanwb is
  attribute syn_hier : string;
  attribute syn_hier of rtl: architecture is "firm";

  -- wishbone/EFB addresses
  constant  I2C1_CR     : slv8 := x"40";
  constant  I2C1_CMDR   : slv8 := x"41";
  constant  I2C1_BR0    : slv8 := x"42";
  constant  I2C1_BR1    : slv8 := x"43";
  constant  I2C1_TXDR   : slv8 := x"44";
  constant  I2C1_SR     : slv8 := x"45";
  constant  I2C1_GCDR   : slv8 := x"46";
  constant  I2C1_RXDR   : slv8 := x"47";
  constant  I2C1_IRQ    : slv8 := x"48";
  constant  I2C1_IRQEN  : slv8 := x"49";

  constant  I2C2_CR     : slv8 := x"4A";
  constant  I2C2_CMDR   : slv8 := x"4B";
  constant  I2C2_BR0    : slv8 := x"4C";
  constant  I2C2_BR1    : slv8 := x"4D";
  constant  I2C2_TXDR   : slv8 := x"4E";
  constant  I2C2_SR     : slv8 := x"4F";
  constant  I2C2_GCDR   : slv8 := x"50";
  constant  I2C2_RXDR   : slv8 := x"51";
  constant  I2C2_IRQ    : slv8 := x"52";
  constant  I2C2_IRQEN  : slv8 := x"53";

  constant  CFG_CR      : slv8 := x"70";
  constant  CFG_TXDR    : slv8 := x"71";
  constant  CFG_SR      : slv8 := x"72";
  constant  CFG_RXDR    : slv8 := x"73";
  constant  CFG_IRQ     : slv8 := x"74";
  constant  CFG_IRQEN   : slv8 := x"75";
  ------------------------------------------
  component efbx is
    port (
      wb_clk_i  : in    std_logic;
      wb_rst_i  : in    std_logic;
      wb_cyc_i  : in    std_logic;
      wb_stb_i  : in    std_logic;
      wb_we_i   : in    std_logic;
      wb_adr_i  : in    std_logic_vector(7 downto 0);
      wb_dat_i  : in    std_logic_vector(7 downto 0);
      wb_dat_o  : out   std_logic_vector(7 downto 0);
      wb_ack_o  : out   std_logic;
      tc_oc     : out   std_logic;
--    i2c1_scl  : inout std_logic;
--    i2c1_sda  : inout std_logic;
--    i2c1_irqo : out   std_logic;
      wb2pll    : out   Twishbone2pll;
      pll2wb    : in    Tpll2wishbone   );
  end component efbx;
  ---------------------------------------------------------------------
  signal  wbCyc
        , wbStb
        , wbWe
        , wbAck_o     : std_logic;
  signal  wbDat_o
        , wbDat_i
        , wbAddr
        , XwbReadback : slv8 := (others=>'0');

begin
  ------------------------------------------------
  -- wishbone state machine
  WBSM_BLK: block

    type TWBstate is ( WBidle, WBwr, WBrd );

    signal  WBstate       : TWBstate;
    signal  XhitWBaddr
          , XhitWBdata
          , XhiNybWritten
          , wbAck         : boolean;
    signal  wbRst         : std_logic;
    signal  XwbAddr
          , XwbData       : slv8 := (others=>'0');

    attribute GSR : string;
    attribute GSR of XwbAddr : signal is "DISABLED";
    attribute GSR of XwbData : signal is "DISABLED";

  begin
    -- used in debug mode to reset the internal 16-bit counters
    wbRst  <= '0'
-- synthesis translate_off
              or (to_sl(ctlReset))
-- synthesis translate_on
              ;
    myEFB: efbx port map ( wb_clk_i   => xclk,
                           wb_rst_i   => wbRst,
                           wb_cyc_i   => wbCyc,
                           wb_stb_i   => wbStb,
                           wb_we_i    => wbWe,
                           wb_adr_i   => wbAddr,
                           wb_dat_i   => wbDat_i,
                           wb_dat_o   => wbDat_o,
                           wb_ack_o   => wbAck_o,
                           tc_oc      => refPWM,
                           wb2pll     => wb2pll,
                           pll2wb     => pll2wb   );

    wbAck <= (wbAck_o = '1');

    process (xclk)
      variable  nextState : TWBstate;
    begin
      if rising_edge(xclk) then
        nextState := WBstate;

        XhitWBaddr <= (XI.PA = EFB_ADDR_REG);
        XhitWBdata <= (XI.PA = EFB_DATA_REG);

        if XhitWBdata and XI.PWr then
          XwbData <= XwbData(3 downto 0) & XI.PD(3 downto 0);
        end if;

        if XhitWBaddr and XI.PWr then
          XwbAddr <= XwbAddr(3 downto 0) & XI.PD(3 downto 0);
        end if;

        XhiNybWritten <= XhitWBdata and XI.PWr and ((XI.PWrSubA mod 2)=1);

        if ctlReset then
          nextState := WBidle;
          wbStb     <= '0';
          wbCyc     <= '0';
          wbWe      <= '0';
        else
          case WBstate is
            -----------------------------------
            when WBidle =>
              if XhiNybWritten then
                wbAddr    <= XwbAddr;
                wbDat_i   <= XwbData;
                XwbAddr   <= n2slv8(ToInteger(XwbAddr)+1);
                nextState := WBwr;
              elsif XI.PRdFinished and XhitWBaddr then      -- read marches one step behind
                wbAddr    <= XwbAddr;
                wbDat_i   <= (others=>'0');
                XwbAddr   <= n2slv8(ToInteger(XwbAddr)+1);
                nextState := WBrd;
              end if;

            -----------------------------------
            -- read cycle
            when WBrd =>
              if wbAck then
                wbStb <= '0';
                wbCyc <= '0';
                nextState := WBidle;
              else
                wbStb <= '1';
                wbCyc <= '1';
              end if;

            -----------------------------------
            -- write cycle
            when WBwr =>
              if wbAck then
                wbStb <= '0';
                wbCyc <= '0';
                wbWe  <= '0';
                nextState := WBidle;
              else
                wbStb <= '1';
                wbCyc <= '1';
                wbWe  <= '1';
              end if;

            -----------------------------------
--          when others =>
--            nextState := WBstart;

          end case;
        end if;

        if XhitWBdata and (wbState = WBrd) and wbAck then
          XwbReadback <= wbDat_o;
        end if;

        if XhitWBdata then
          XO <= XwbReadback;
        else
          XO <= (others=>'0');
        end if;

        WBstate <= nextState;
      end if;
    end process;

  end block WBSM_BLK;

end rtl;
-----------------------------------------------------------------------
-- EOF fanwb.vhd
