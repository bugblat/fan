----------------------------------------------------------------------------
--
-- UTILS.VHD    utility definitions and functions
--
-- Initial entry: heaven know when.
-- updated      : 05-Jan-12 te
----------------------------------------------------------------------------
library ieee;                   use ieee.std_logic_1164.all;
library work;

package attributes is

  attribute keep_hierarchy  : string;
  attribute syn_keep        : boolean;
  attribute syn_preserve    : boolean;       -- preserve FFs

  attribute syn_hier: string;

  -- net attributes
  attribute syn_maxfan : integer;

  -- IOB attributes
  attribute PULLMODE: string;
  attribute IO_TYPE : string;

end package attributes;

----------------------------------------------------------------------------
library ieee;                   use ieee.std_logic_1164.all;
                                use ieee.numeric_std.all;
library work;

package utils is

  -- save lots of typing
  subtype slv2  is std_logic_vector( 1 downto 0);
  subtype slv3  is std_logic_vector( 2 downto 0);
  subtype slv4  is std_logic_vector( 3 downto 0);
  subtype slv5  is std_logic_vector( 4 downto 0);
  subtype slv6  is std_logic_vector( 5 downto 0);
  subtype slv7  is std_logic_vector( 6 downto 0);
  subtype slv8  is std_logic_vector( 7 downto 0);
  subtype slv9  is std_logic_vector( 8 downto 0);
  subtype slv10 is std_logic_vector( 9 downto 0);
  subtype slv11 is std_logic_vector(10 downto 0);
  subtype slv12 is std_logic_vector(11 downto 0);
  subtype slv13 is std_logic_vector(12 downto 0);
  subtype slv14 is std_logic_vector(13 downto 0);
  subtype slv15 is std_logic_vector(14 downto 0);
  subtype slv16 is std_logic_vector(15 downto 0);
  subtype slv17 is std_logic_vector(16 downto 0);
  subtype slv18 is std_logic_vector(17 downto 0);
  subtype slv19 is std_logic_vector(18 downto 0);
  subtype slv20 is std_logic_vector(19 downto 0);
  subtype slv21 is std_logic_vector(20 downto 0);
  subtype slv22 is std_logic_vector(21 downto 0);
  subtype slv23 is std_logic_vector(22 downto 0);
  subtype slv24 is std_logic_vector(23 downto 0);
  subtype slv25 is std_logic_vector(24 downto 0);
  subtype slv26 is std_logic_vector(25 downto 0);
  subtype slv27 is std_logic_vector(26 downto 0);
  subtype slv28 is std_logic_vector(27 downto 0);
  subtype slv29 is std_logic_vector(28 downto 0);
  subtype slv30 is std_logic_vector(29 downto 0);
  subtype slv31 is std_logic_vector(30 downto 0);
  subtype slv32 is std_logic_vector(31 downto 0);
  subtype slv36 is std_logic_vector(35 downto 0);
  subtype slv64 is std_logic_vector(63 downto 0);

  subtype sulv2  is std_ulogic_vector( 1 downto 0);
  subtype sulv3  is std_ulogic_vector( 2 downto 0);
  subtype sulv4  is std_ulogic_vector( 3 downto 0);
  subtype sulv5  is std_ulogic_vector( 4 downto 0);
  subtype sulv6  is std_ulogic_vector( 5 downto 0);
  subtype sulv7  is std_ulogic_vector( 6 downto 0);
  subtype sulv8  is std_ulogic_vector( 7 downto 0);
  subtype sulv9  is std_ulogic_vector( 8 downto 0);
  subtype sulv10 is std_ulogic_vector( 9 downto 0);
  subtype sulv11 is std_ulogic_vector(10 downto 0);
  subtype sulv12 is std_ulogic_vector(11 downto 0);
  subtype sulv13 is std_ulogic_vector(12 downto 0);
  subtype sulv14 is std_ulogic_vector(13 downto 0);
  subtype sulv15 is std_ulogic_vector(14 downto 0);
  subtype sulv16 is std_ulogic_vector(15 downto 0);
  subtype sulv17 is std_ulogic_vector(16 downto 0);
  subtype sulv18 is std_ulogic_vector(17 downto 0);
  subtype sulv19 is std_ulogic_vector(18 downto 0);
  subtype sulv20 is std_ulogic_vector(19 downto 0);
  subtype sulv21 is std_ulogic_vector(20 downto 0);
  subtype sulv22 is std_ulogic_vector(21 downto 0);
  subtype sulv23 is std_ulogic_vector(22 downto 0);
  subtype sulv24 is std_ulogic_vector(23 downto 0);
  subtype sulv25 is std_ulogic_vector(24 downto 0);
  subtype sulv26 is std_ulogic_vector(25 downto 0);
  subtype sulv27 is std_ulogic_vector(26 downto 0);
  subtype sulv28 is std_ulogic_vector(27 downto 0);
  subtype sulv29 is std_ulogic_vector(28 downto 0);
  subtype sulv30 is std_ulogic_vector(29 downto 0);
  subtype sulv31 is std_ulogic_vector(30 downto 0);
  subtype sulv32 is std_ulogic_vector(31 downto 0);

  subtype NYB_0  is integer range (4*0+3) downto (4*0);
  subtype NYB_1  is integer range (4*1+3) downto (4*1);
  subtype NYB_2  is integer range (4*2+3) downto (4*2);
  subtype NYB_3  is integer range (4*3+3) downto (4*3);

  subtype HEX_0  is integer range (6*0+5) downto (6*0);
  subtype HEX_1  is integer range (6*1+5) downto (6*1);
  subtype HEX_2  is integer range (6*2+5) downto (6*2);
  subtype HEX_3  is integer range (6*3+5) downto (6*3);
  subtype HEX_4  is integer range (6*4+5) downto (6*4);
  subtype HEX_5  is integer range (6*5+5) downto (6*5);
  subtype HEX_6  is integer range (6*6+5) downto (6*6);
  subtype HEX_7  is integer range (6*7+5) downto (6*7);

  subtype BYTE_0 is integer range (8*0+7) downto (8*0);
  subtype BYTE_1 is integer range (8*1+7) downto (8*1);
  subtype BYTE_2 is integer range (8*2+7) downto (8*2);
  subtype BYTE_3 is integer range (8*3+7) downto (8*3);
  subtype BYTE_4 is integer range (8*4+7) downto (8*4);
  subtype BYTE_5 is integer range (8*5+7) downto (8*5);
  subtype BYTE_6 is integer range (8*6+7) downto (8*6);
  subtype BYTE_7 is integer range (8*7+7) downto (8*7);

  subtype WORD_0 is integer range (16*0+15) downto (16*0);
  subtype WORD_1 is integer range (16*1+15) downto (16*1);
  subtype WORD_2 is integer range (16*2+15) downto (16*2);
  subtype WORD_3 is integer range (16*3+15) downto (16*3);

  -- intercept conv_integer and to_integer calls
  function ToInteger(arg: std_logic_vector) return integer;
  function ToInteger(arg:         unsigned) return integer;
  function ToInteger(arg:           signed) return integer;

  -- convert boolean to std_logic ( t->1, f->0 )
  function to_sl(b: boolean) return std_logic;

  -- convert to std_logic vector
  function n2slv   (n,l: natural ) return std_logic_vector;

  function n2slv2  (n: natural ) return slv2;
  function n2slv3  (n: natural ) return slv3;
  function n2slv4  (n: natural ) return slv4;
  function n2slv8  (n: natural ) return slv8;
  function n2slv24 (n: natural ) return slv24;
  function i2slv32 (n: integer ) return slv32;

  function n2sulv   (n,l: natural ) return std_ulogic_vector;

  function n2sulv2  (n: natural ) return sulv2;
  function n2sulv3  (n: natural ) return sulv3;
  function n2sulv4  (n: natural ) return sulv4;
  function n2sulv8  (n: natural ) return sulv8;

  function itoa( x : integer ) return string;

end package utils;

package body utils is

  -------------------------------------------------------------------------
  -- put the to_integer/conv_integer resolution in one place
  function ToInteger(arg: unsigned) return integer is
    variable x: unsigned(arg'range);
    variable n: integer;
  begin
    x := arg;
    -- synthesis translate_off
    for i in x'range loop
      if x(i)/='1' then       -- resolve the 'undefined' signals
        x(i) := '0';
      end if;
    end loop;
    -- synthesis translate_on
    n := to_integer(x);
    return n;
  end;
  -------------------------------------------------------------------------
  function ToInteger(arg: signed) return integer is
    variable x: signed(arg'range);
    variable n: integer;
  begin
    x := arg;
    -- synthesis translate_off
    for i in x'range loop
      if x(i)/='1' then
        x(i) := '0';
      end if;
    end loop;
    -- synthesis translate_on
    n := to_integer(x);
    return n;
  end;
  -------------------------------------------------------------------------
  function ToInteger(arg: std_logic_vector) return integer is
    variable x: unsigned(arg'range);
    variable n: integer;
  begin
    x := unsigned(arg);
    -- synthesis translate_off
    for i in x'range loop
      if x(i)/='1' then       -- resolve the 'undefined' signals
        x(i) := '0';
      end if;
    end loop;
    -- synthesis translate_on
    n := to_integer(x);
    return n;
  end;
  -------------------------------------------------------------------------
  function ToInteger(arg: std_ulogic_vector) return integer is
    variable x: std_logic_vector(arg'range);
  begin
    x := std_logic_vector(arg);
    return ToInteger(x);
  end;
  -------------------------------------------------------------------------
  function to_sl(b: boolean) return std_logic is
    variable s: std_logic;
  begin
    if b then s :='1'; else s :='0'; end if;
    return s;
  end to_sl;
  -------------------------------------------------------------------------
  function n2slv ( N,L: natural ) return std_logic_vector is
    variable vec: std_logic_vector(L-1 downto 0);
    variable Nx : natural;
  begin
    Nx := N rem 2**L;
    vec := std_logic_vector(to_unsigned(Nx,L));
    return vec;
  end;
  function n2slv2 (n: natural) return slv2  is begin return n2slv(n, 2); end;
  function n2slv3 (n: natural) return slv3  is begin return n2slv(n, 3); end;
  function n2slv4 (n: natural) return slv4  is begin return n2slv(n, 4); end;
  function n2slv8 (n: natural) return slv8  is begin return n2slv(n, 8); end;
  function n2slv24(n: natural) return slv24 is begin return n2slv(n,24); end;
  -------------------------------------------------------------------------
  function n2sulv ( N,L: natural ) return std_ulogic_vector is
    variable vec: std_ulogic_vector(L-1 downto 0);
    variable Nx : natural;
  begin
    Nx := N rem 2**L;
    vec := std_ulogic_vector(to_unsigned(Nx,L));
    return vec;
  end;
 function n2sulv2(n: natural) return sulv2 is begin return n2sulv(n, 2); end;
 function n2sulv3(n: natural) return sulv3 is begin return n2sulv(n, 3); end;
 function n2sulv4(n: natural) return sulv4 is begin return n2sulv(n, 4); end;
 function n2sulv8(n: natural) return sulv8 is begin return n2sulv(n, 8); end;
  -------------------------------------------------------------------------
  function i2slv ( N,L: integer ) return std_logic_vector is
    variable vec: std_logic_vector(L-1 downto 0);
  begin
    vec := std_logic_vector(to_signed(n,L));
    return vec;
  end;
  function i2slv32(n: integer) return slv32 is begin return i2slv(n,32); end;
  -------------------------------------------------------------------------
  type TStr10 is array (0 to 9) of string(1 to 1);
  constant Str10: TStr10 := ("0","1","2","3","4","5","6","7","8","9");

  function itoa( x : integer ) return string is
    variable n: integer := x;
  begin
    if n < 0 then
      return "-" & itoa(-n);
    elsif n < 10 then
      return Str10(n);
    else
      return itoa(n/10) & Str10(n rem 10);
    end if;
  end function itoa;
  -------------------------------------------------------------------------

end package body utils; -- EOF utils.vhd
