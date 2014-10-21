-----------------------------------------------------------------------
-- fanefb.vhd   Bugblat fan logic analyser EFB
--
-- Initial entry: 05-Jan-12 te
--
-- see copyright notice in fandefs.vhd
-----------------------------------------------------------------------
library ieee;           use ieee.std_logic_1164.all;
library work;           use work.defs.all;
library machxo2;        use machxo2.components.all;

entity efbx is                -- no I2C in this version
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
--      i2c1_scl  : inout std_logic;
--      i2c1_sda  : inout std_logic;
--      i2c1_irqo : out   std_logic;
        wb2pll    : out   Twishbone2pll;
        pll2wb    : in    Tpll2wishbone   );
end efbx;

architecture struct of efbx is
begin
    EFB_0: EFB
      generic map (
        EFB_I2C1              => "DISABLED",
        EFB_I2C2              => "DISABLED",
        EFB_SPI               => "DISABLED",
        EFB_TC                => "ENABLED",
        EFB_TC_PORTMODE       => "WB",
        EFB_UFM               => "ENABLED",
        EFB_WB_CLK_FREQ       => "24.0",

        UFM_INIT_FILE_FORMAT  => "HEX",
        UFM_INIT_FILE_NAME    => "NONE",
        UFM_INIT_ALL_ZEROS    => "ENABLED",
        UFM_INIT_START_PAGE   =>  0,
        UFM_INIT_PAGES        =>  0,
        DEV_DENSITY           => "2000L",

        GSR                   => "ENABLED",
        TC_ICAPTURE           => "DISABLED",
        TC_OVERFLOW           => "DISABLED",
        TC_ICR_INT            => "OFF",
        TC_OCR_INT            => "OFF",
        TC_OV_INT             => "OFF",
        TC_TOP_SEL            => "ON",
        TC_RESETN             => "ENABLED",         -- used in debug mode only
        TC_OC_MODE            => "WAVE_GENERATOR",
        TC_OCR_SET            =>  37,               -- 66 - 2*14 - 1
        TC_TOP_SET            =>  65,               -- 66 - 1.....
        TC_CCLK_SEL           =>  1,
        TC_MODE               => "FASTPWM",
        TC_SCLK_SEL           => "PCLOCK",

        SPI_WAKEUP            => "DISABLED",
        SPI_INTR_RXOVR        => "DISABLED",
        SPI_INTR_TXOVR        => "DISABLED",
        SPI_INTR_RXRDY        => "DISABLED",
        SPI_INTR_TXRDY        => "DISABLED",
        SPI_SLAVE_HANDSHAKE   => "DISABLED",
        SPI_PHASE_ADJ         => "DISABLED",
        SPI_CLK_INV           => "DISABLED",
        SPI_LSB_FIRST         => "DISABLED",
        SPI_CLK_DIVIDER       =>  1,
        SPI_MODE              => "MASTER",

        I2C2_WAKEUP           => "DISABLED",
        I2C2_GEN_CALL         => "DISABLED",
        I2C2_CLK_DIVIDER      =>  17,
        I2C2_BUS_PERF         => "400kHz",
        I2C2_SLAVE_ADDR       => "0b0011001",
        I2C2_ADDRESSING       => "7BIT",

        I2C1_WAKEUP           => "DISABLED",
        I2C1_GEN_CALL         => "DISABLED",
        I2C1_CLK_DIVIDER      =>  17,
        I2C1_BUS_PERF         => "400kHz",
        I2C1_SLAVE_ADDR       => "0b1000001",
        I2C1_ADDRESSING       => "7BIT"       )
      port map (
        WBCLKI      => wb_clk_i,
        WBRSTI      => wb_rst_i,
        WBCYCI      => wb_cyc_i,
        WBSTBI      => wb_stb_i,
        WBWEI       => wb_we_i,
        WBADRI7     => wb_adr_i(7),
        WBADRI6     => wb_adr_i(6),
        WBADRI5     => wb_adr_i(5),
        WBADRI4     => wb_adr_i(4),
        WBADRI3     => wb_adr_i(3),
        WBADRI2     => wb_adr_i(2),
        WBADRI1     => wb_adr_i(1),
        WBADRI0     => wb_adr_i(0),
        WBDATI7     => wb_dat_i(7),
        WBDATI6     => wb_dat_i(6),
        WBDATI5     => wb_dat_i(5),
        WBDATI4     => wb_dat_i(4),
        WBDATI3     => wb_dat_i(3),
        WBDATI2     => wb_dat_i(2),
        WBDATI1     => wb_dat_i(1),
        WBDATI0     => wb_dat_i(0),

        PLL0DATI7   => pll2wb.data(7),
        PLL0DATI6   => pll2wb.data(6),
        PLL0DATI5   => pll2wb.data(5),
        PLL0DATI4   => pll2wb.data(4),
        PLL0DATI3   => pll2wb.data(3),
        PLL0DATI2   => pll2wb.data(2),
        PLL0DATI1   => pll2wb.data(1),
        PLL0DATI0   => pll2wb.data(0),
        PLL0ACKI    => pll2wb.ack,
        PLL1DATI7   => '0',
        PLL1DATI6   => '0',
        PLL1DATI5   => '0',
        PLL1DATI4   => '0',
        PLL1DATI3   => '0',
        PLL1DATI2   => '0',
        PLL1DATI1   => '0',
        PLL1DATI0   => '0',
        PLL1ACKI    => '0',

        I2C1SCLI    => '0',
        I2C1SDAI    => '0',
        I2C2SCLI    => '0',
        I2C2SDAI    => '0',

        SPISCKI     => '0',
        SPIMISOI    => '0',
        SPIMOSII    => '0',
        SPISCSN     => '0',

        TCCLKI      => wb_clk_i,
        TCRSTN      => "not"(wb_rst_i),   -- resets internal 16-bit clock
        TCIC        => '0',               -- input capture trigger event

        UFMSN       => '1',
        WBDATO7     => wb_dat_o(7),
        WBDATO6     => wb_dat_o(6),
        WBDATO5     => wb_dat_o(5),
        WBDATO4     => wb_dat_o(4),
        WBDATO3     => wb_dat_o(3),
        WBDATO2     => wb_dat_o(2),
        WBDATO1     => wb_dat_o(1),
        WBDATO0     => wb_dat_o(0),
        WBACKO      => wb_ack_o,
        PLLCLKO     => wb2pll.clk,
        PLLRSTO     => wb2pll.rst,
        PLL0STBO    => wb2pll.stb,
        PLL1STBO    => open,
        PLLWEO      => wb2pll.we,
        PLLADRO4    => wb2pll.addr(4),
        PLLADRO3    => wb2pll.addr(3),
        PLLADRO2    => wb2pll.addr(2),
        PLLADRO1    => wb2pll.addr(1),
        PLLADRO0    => wb2pll.addr(0),
        PLLDATO7    => wb2pll.data(7),
        PLLDATO6    => wb2pll.data(6),
        PLLDATO5    => wb2pll.data(5),
        PLLDATO4    => wb2pll.data(4),
        PLLDATO3    => wb2pll.data(3),
        PLLDATO2    => wb2pll.data(2),
        PLLDATO1    => wb2pll.data(1),
        PLLDATO0    => wb2pll.data(0),

        I2C1SCLO    => open,
        I2C1SCLOEN  => open,
        I2C1SDAO    => open,
        I2C1SDAOEN  => open,
        I2C1IRQO    => open,

        I2C2SCLO    => open,
        I2C2SCLOEN  => open,
        I2C2SDAO    => open,
        I2C2SDAOEN  => open,
        I2C2IRQO    => open,

        SPISCKO     => open,
        SPISCKEN    => open,
        SPIMISOO    => open,
        SPIMISOEN   => open,
        SPIMOSIO    => open,
        SPIMOSIEN   => open,
        SPIMCSN7    => open,
        SPIMCSN6    => open,
        SPIMCSN5    => open,
        SPIMCSN4    => open,
        SPIMCSN3    => open,
        SPIMCSN2    => open,
        SPIMCSN1    => open,
        SPIMCSN0    => open,
        SPICSNEN    => open,
        SPIIRQO     => open,

        TCINT       => open,
        TCOC        => tc_oc,

        WBCUFMIRQ   => open,
        CFGWAKE     => open,
        CFGSTDBY    => open  );

end struct;
-- EOF fanefb.vhd -----------------------------------------------------
