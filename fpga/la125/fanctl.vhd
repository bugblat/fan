-----------------------------------------------------------------------
-- fanctl.vhd    Bugblat fan logic analyser reset/run/etc logic
--
-- Initial entry: 31-May-13 te
--
-- see copyright notice in fandefs.vhd
-----------------------------------------------------------------------
library ieee;     use ieee.std_logic_1164.all, ieee.numeric_std.all;
library work;     use work.utils.all, work.defs.all;

entity fanctl is
  port (ID0, ID1,
        xclk, sclk      : in    std_logic;
        CtlRec          : out   TCtlRec;
        XI              : in    XIrec;
        XO              : out   slv8      );
end fanctl;

architecture rtl of fanctl is
  signal  Reset               : boolean := true;
  signal  Run, Stop, ResetPLL : boolean := false;

  signal  clockTypeReg        : TClockType := CT_X1;
  signal  scratchReg          : TctlData := n2slv(CHANS, CTL_DATA_BITS);

begin
  ---------------------------------------------------------------------
  process (xclk)
  begin
    if rising_edge(xclk) then
      if XI.PWr then
        case XI.PA is
          when CONTROL_REG =>
            Reset    <= XI.PD(CTL_RESET)    = '1';
            Run      <= XI.PD(CTL_RUN)      = '1';
            Stop     <= XI.PD(CTL_STOP)     = '1';
            ResetPLL <= XI.PD(CTL_RESETCLK) = '1';

          when CLOCK_TYPE_REG =>
            clockTypeReg <= ToInteger(XI.PD(CTL_CT_2 downto CTL_CT_0));

          when SCRATCH_REG =>
            scratchReg <= XI.PD;

          when others => null;
        end case;
      end if;
    end if;
  end process;

  -- resynchronise control bits to the logic clock
  process (sclk) begin
    if rising_edge(sclk) then
      CtlRec.Reset    <= Reset;
      CtlRec.Run      <= Run;
      CtlRec.Stop     <= Stop;
    end if;
  end process;

  CtlRec.ClockType  <= clockTypeReg;
  CtlRec.ResetClock <= ResetPLL;

  -----------------------------------------------
  -- register readback
  process (xclk)
    variable IDrevision, IDbits, IDletter : slv8;
  begin
    if rising_edge(xclk) then
      IDrevision := "01" & n2slv(REVISION, 6);         -- 41h='A'..5Ah='Z'
      IDbits     := "001100" &  ID1 & ID0;             -- 30h..33h='0'..'3'
      IDletter   := n2slv4(6) & n2slv4(XI.PRdSubA);    -- 61h='a'...

      case XI.PA is
        when ID_REG =>
          case (XI.PRdSubA mod 32) is
            when 0      => XO <= ID;                  -- in the 'defs' file
            when 1      => XO <= IDrevision;
            when 2      => XO <= IDbits;
            when others => XO <= IDletter;
          end case;

        when CONTROL_REG =>
          XO <= (CTL_RESET     => to_sl(Reset),
                 CTL_RUN       => to_sl(Run),
                 CTL_STOP      => to_sl(Stop),
                 CTL_RESETCLK  => to_sl(ResetPLL),
                 others        => '0'    );

        when CLOCK_TYPE_REG =>
          XO <= n2slv8( clockTypeReg );

        when SCRATCH_REG =>
          XO <= "01" & scratchReg;

        when others =>
          XO <= (others=>'0');

      end case;
    end if;
  end process;

end rtl;
-- EOF fanctl.vhd -----------------------------------------------------
