-----------------------------------------------------------------------
-- fanbram.vhd    Bugblat fan -- BRAMs
--
-- Initial entry: 05-Jan-12 te
--
-- see copyright notice in fandefs.vhd
-----------------------------------------------------------------------
-- 8 BRAMs, each organised as
--   write : 18 bits wide, 512 deep. i.e.  9 bit write address.
--   read  : 18 bits wide, 512 deep. i.e.  9 bit read address.
--
-- four sets of BRAMs, two BRAMs in each set.
--   write : 12b write addr, including 3b to select correct BRAM
--   read  : 10b read addr, BRAM selection in external logic
-----------------------------------------------------------------------
library ieee;           use ieee.std_logic_1164.all, IEEE.numeric_std.all;
library work;           use work.utils.all, work.defs.all;
library machxo2;        use machxo2.components.all;

entity bram is generic (IX          : integer );
                  port (sclk, xclk  : in  std_logic;
                        bramWA      : in  slv12;
                        bramRA      : in  slv9;
                        bramDin     : in  slv18;
                        bramWE,
                        bramReset   : in  boolean;
                        bramDout    : out slv18       );
end bram;

architecture struct of bram is
  -------------------------------------------------
  function ix2csString( x : integer ) return string is
    variable v: string(1 to 5) := "0b111";
    variable c: character;
  begin
    if ((x/4) mod 2)=0 then v(3) := '0'; end if;
    if ((x/2) mod 2)=0 then v(4) := '0'; end if;
    if ((x/1) mod 2)=0 then v(5) := '0'; end if;
    return v;
  end function ix2csString;
  -------------------------------------------------

  constant CSDW: string(1 to 5)  := ix2csString(IX);
  constant Z0  : string(1 to 82) := ( 2=>'x', others=>'0');

begin
  RAM9K_PDP: PDPW8KC
    generic map (
      INITVAL_1F => Z0, INITVAL_1E => Z0, INITVAL_1D => Z0, INITVAL_1C => Z0,
      INITVAL_1B => Z0, INITVAL_1A => Z0, INITVAL_19 => Z0, INITVAL_18 => Z0,
      INITVAL_17 => Z0, INITVAL_16 => Z0, INITVAL_15 => Z0, INITVAL_14 => Z0,
      INITVAL_13 => Z0, INITVAL_12 => Z0, INITVAL_11 => Z0, INITVAL_10 => Z0,
      INITVAL_0F => Z0, INITVAL_0E => Z0, INITVAL_0D => Z0, INITVAL_0C => Z0,
      INITVAL_0B => Z0, INITVAL_0A => Z0, INITVAL_09 => Z0, INITVAL_08 => Z0,
      INITVAL_07 => Z0, INITVAL_06 => Z0, INITVAL_05 => Z0, INITVAL_04 => Z0,
      INITVAL_03 => Z0, INITVAL_02 => Z0, INITVAL_01 => Z0, INITVAL_00 => Z0,
      INIT_DATA           => "STATIC",
      ASYNC_RESET_RELEASE => "SYNC",
      RESETMODE           => "SYNC",
      REGMODE             => "OUTREG",
      CSDECODE_W          => CSDW,
      CSDECODE_R          => "0b000",
      GSR                 => "ENABLED",
      DATA_WIDTH_W        => 18,
      DATA_WIDTH_R        => 18   )
    port map (
      CSW2  =>  bramWA(11),
      CSW1  =>  bramWA(10),
      CSW0  =>  bramWA(9),

      ADW8  =>  bramWA(8),
      ADW7  =>  bramWA(7),
      ADW6  =>  bramWA(6),
      ADW5  =>  bramWA(5),
      ADW4  =>  bramWA(4),
      ADW3  =>  bramWA(3),
      ADW2  =>  bramWA(2),
      ADW1  =>  bramWA(1),
      ADW0  =>  bramWA(0),

      DI17  =>  bramDin(17),
      DI16  =>  bramDin(16),
      DI15  =>  bramDin(15),
      DI14  =>  bramDin(14),
      DI13  =>  bramDin(13),
      DI12  =>  bramDin(12),
      DI11  =>  bramDin(11),
      DI10  =>  bramDin(10),
      DI9   =>  bramDin(9),
      DI8   =>  bramDin(8),
      DI7   =>  bramDin(7),
      DI6   =>  bramDin(6),
      DI5   =>  bramDin(5),
      DI4   =>  bramDin(4),
      DI3   =>  bramDin(3),
      DI2   =>  bramDin(2),
      DI1   =>  bramDin(1),
      DI0   =>  bramDin(0),

      CSR2  =>  '0',
      CSR1  =>  '0',
      CSR0  =>  '0',
      ADR12 =>  bramRA(8),
      ADR11 =>  bramRA(7),
      ADR10 =>  bramRA(6),
      ADR9  =>  bramRA(5),
      ADR8  =>  bramRA(4),
      ADR7  =>  bramRA(3),
      ADR6  =>  bramRA(2),
      ADR5  =>  bramRA(1),
      ADR4  =>  bramRA(0),
      ADR3  =>  '0',
      ADR2  =>  '0',
      ADR1  =>  '0',
      ADR0  =>  '0',
      DO17  =>  bramDout(8),      -- BYTE reversed!
      DO16  =>  bramDout(7),
      DO15  =>  bramDout(6),
      DO14  =>  bramDout(5),
      DO13  =>  bramDout(4),
      DO12  =>  bramDout(3),
      DO11  =>  bramDout(2),
      DO10  =>  bramDout(1),
      DO9   =>  bramDout(0),

      DO8   =>  bramDout(17),
      DO7   =>  bramDout(16),
      DO6   =>  bramDout(15),
      DO5   =>  bramDout(14),
      DO4   =>  bramDout(13),
      DO3   =>  bramDout(12),
      DO2   =>  bramDout(11),
      DO1   =>  bramDout(10),
      DO0   =>  bramDout(9),

      CLKW  =>   sClk,
      CLKR  =>   xclk,
      CEW   =>   '1',
      CER   =>   '1',
      BE1   =>   to_sl(bramWE),
      BE0   =>   to_sl(bramWE),
      OCER  =>   '1',
      RST   =>   to_sl(bramReset)
      );

end struct;

-----------------------------------------------------------------------
library ieee;           use ieee.std_logic_1164.all, IEEE.numeric_std.all;
library work;           use work.utils.all, work.defs.all;

entity fanbram is port (sclk   : in  std_logic;
                        xclk   : in  std_logic;
                        wrAddr : in  TBramWrAddr;
                        wrData : in  TBramWrData;
                        wrEna,
                        reset  : in  boolean;
                        XI     : in  XIrec;
                        XO     : out slv8      );
end fanbram;

architecture rtl of fanbram is
  attribute syn_hier: string;
  attribute syn_hier of rtl: architecture is "hard";

  -- one dual-port BRAM -----------------------------------------------
  constant DPR_WA_BITS  : integer := 12;
  constant DPR_RA_BITS  : integer :=  9;

  subtype TdprWrAddr is std_logic_vector(DPR_WA_BITS-1 downto 0);
  subtype TdprRdAddr is std_logic_vector(DPR_RA_BITS-1 downto 0);

  -----------------------------------------------
  component bram generic ( IX         : integer );
                    port ( sclk, xclk : in  std_logic;
                           bramWA     : in  TdprWrAddr;
                           bramRA     : in  TdprRdAddr;
                           bramDin    : in  slv18;
                           bramWE,
                           bramReset  : in  boolean;
                           bramDout   : out slv18       );
  end component bram;
  -----------------------------------------------

  type TdOut is array (0 to NUMRAMS-1) of slv18;
  signal  dOut    : Tdout;
  signal  ramDO   : slv18;
  signal  rdAddr  : unsigned(TBramRdAddr'range);

begin
  -------------------------------------------------
  G_RAM: for ix in 0 to NUMRAMS-1 generate
    signal bwa : TdprWrAddr;
    signal bra : TdprRdAddr;
  begin
    bwa <= wrAddr(bwa'range);
    bra <= std_logic_vector(rdAddr(bra'range));
    R: bram generic map ( IX          => ix      )
               port map ( sclk        => sclk,
                          xclk        => xclk,
                          bramWA      => bwa,
                          bramRA      => bra,
                          bramDin     => wrData,
                          bramWE      => wrEna,
                          bramReset   => false,
                          bramDout    => dOut(ix) );
  end generate G_RAM;

  -------------------------------------------------
  -- reduce dOut to ramDO
  process (xclk)
    variable ix : integer range 0 to NUMRAMS-1;
  begin
    if rising_edge(xclk) then
      ix := toInteger(rdAddr(rdAddr'high downto DPR_RA_BITS));
      ramDO <= dOut(ix);
    end if;
  end process;

  -------------------------------------------------
  -- readout of 18-bit values over the 8-bit XO bus.
  -- three 8-bit reads, 7..0, 15..8, 17..16
  RA_B : block
    subtype RAHI is integer range (rdAddr'high-XI.PD'length) downto 0;
    signal  stage : integer range 0 to 2;
  begin
    process (xclk) begin
      if rising_edge(xclk) then

        -- increment stage every read
        if reset then
          stage <= 0;
        elsif XI.PWr and (XI.PA=RAM_ADDR_REG) then
          stage <= 0;
        elsif XI.PRdFinished and (XI.PA = RAM_DATA_REG) then
          if stage >= 2 then
            stage <= 0;
          else
            stage <= stage+1;
          end if;
        end if;

        -- increment address every three reads
        if reset then
          rdAddr <= (others=>'0');
        elsif XI.PWr and (XI.PA=RAM_ADDR_REG) then
          rdAddr <= rdAddr(RAHI) & unsigned(XI.PD);
        elsif XI.PRdFinished and (XI.PA = RAM_DATA_REG) and (stage = 2) then
          rdAddr <= rdAddr+1;             -- no maxAddr - address loops round
        end if;

        if (XI.PA = RAM_DATA_REG) then
          case stage is
            when 0 =>   XO <= ramDO(BYTE_0);
            when 1 =>   XO <= ramDO(BYTE_1);
            when 2 =>   XO <= "000000" & ramDO(17 downto 16);
          end case;
        else
          XO <= (others=>'0');
        end if;

      end if;
    end process;
  end block RA_B;

end rtl;
-- EOF fanbram.vhd -------------------------------------------------------
