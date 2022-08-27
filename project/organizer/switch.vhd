----------------------------------------------------------
-- this file is a result of some exercices in my Altera --
-- book dedicated to generic device wxample and timers  --
-- Copyright (C) Amos Zaslavsky / www.aztech.co.il      --
----------------------------------------------------------
 
------------------------------------------------
-- a simple sync rise detector used in        --
-- autorepeat, doubleclick, switch components --
------------------------------------------------
library ieee ;
use ieee.std_logic_1164.all ;
use ieee.std_logic_unsigned.all ;
entity xrise is
   port ( resetN,clk,din : in  std_logic ;
          dout           : out std_logic ) ;
end xrise ;
architecture arc_xrise of xrise is
   signal sampled1 , sampled2 : std_logic ;
begin
    process ( clk , resetN )
    begin
       if resetN = '0' then
          sampled1 <= '0' ;
          sampled2 <= '0' ;
       elsif clk'event and clk = '1' then
          sampled1 <= din      ;
          sampled2 <= sampled1 ;
       end if ;
    end process ;
    dout <= sampled1 and not sampled2 ;
end arc_xrise ;

-----------------------------------------
-- a simple sync fall detector used in --
-- the switch component                --
-----------------------------------------
library ieee ;
use ieee.std_logic_1164.all ;
use ieee.std_logic_unsigned.all ;
entity xfall is
   port ( resetN,clk,din : in  std_logic ;
          dout           : out std_logic ) ;
end xfall ;
architecture arc_xfall of xfall is
   signal sampled1 , sampled2 : std_logic ;
begin
    process ( clk , resetN )
    begin
       if resetN = '0' then
          sampled1 <= '0' ;
          sampled2 <= '0' ;
       elsif clk'event and clk = '1' then
          sampled1 <= din      ;
          sampled2 <= sampled1 ;
       end if ;
    end process ;
    dout <= not sampled1 and sampled2 ;
end arc_xfall ;

------------------------------------------
-- Generic On-Delay timer (0 stretcher) --
-- Copyright (C) Amoz Zaslavsky         --
------------------------------------------
library ieee ;
use ieee.std_logic_1164.all ;
entity ton is
   generic (delay : positive := 50000000 ) ;
   port ( resetN  : in  std_logic ;
          clk     : in  std_logic ;
          te      : in  std_logic ;
          tout    : out std_logic ) ;
end ton ;
architecture arc_ton of ton is
   signal count : integer range 0 to delay ;
begin
   process ( resetN , clk )
   begin
      if resetN = '0' then
         count <= delay ;
      elsif clk'event and clk = '1' then
         if    te = '0' then
            count <= delay ;
         elsif 0 < count then
            count <= count - 1 ;
         end if ;
      end if ;
   end process ;
   tout <= '0' when 0 < count else '1' ;
end arc_ton ;

-----------------------------------
-- Generic Repeater Timer        --
-- copyright (C) Amos Zaslavsky  --
-----------------------------------
library ieee ;
use ieee.std_logic_1164.all ;
entity trep is
   generic ( delay : integer range
      2 to integer'high := 25000000 ) ;
   port ( resetN  : in  std_logic ;
          clk     : in  std_logic ;
          din     : in  std_logic ;
          dout    : out std_logic ) ;
end trep ;
architecture arc_trep of trep is
   signal ds1,ds2,dint,tc : std_logic ;
   signal count : integer range 0 to delay - 1 ;
begin
   -- embedded Rise detector
   process ( resetN , clk )
   begin
      if resetN = '0' then
         ds1 <= '0' ;
         ds2 <= '0' ;
      elsif clk'event and clk = '1' then
         ds1 <= din ;
         ds2 <= ds1 ;
      end if ;
   end process ;
   dint <= not ds2 and ds1 ;
    -- Counter
   process (resetN,clk)
   begin
      if resetN = '0' then
         count <=  delay-1 ;
      elsif clk'event and clk = '1' then
         if      ds2 = '0' or  tc = '1'  then
            count <= delay - 1 ;
         else -- ds2 = '1' and tc = '0'
            count <= count - 1 ;
         end if ;
      end if ;
   end process ;
   tc <= '1' when count = 0 else '0' ;
   -- Immediate or delayed output
   dout <=  dint or tc ;
   -- For delayed output only, choose this assignment to tc
   -- dout <= tc ;
end arc_trep ;

-------------------------------------------
-- Generic Off-Delay timer (1 stretcher) --
-- Copyright (C) Amoz Zaslavsky          --
-------------------------------------------
library ieee ;
use ieee.std_logic_1164.all ;
entity toff is
   generic (delay : positive := 50000000 ) ;
   port ( resetN  : in  std_logic ;
          clk     : in  std_logic ;
          din     : in  std_logic ;
          sc      : in  std_logic ;
          dout    : out std_logic ) ;
end toff ;
architecture arc_toff of toff is
   signal count : integer range 0 to delay ;
begin
   process ( resetN , clk )
   begin
      if resetN = '0' then
         count <= 0 ;
      elsif clk'event and clk = '1' then
         if     sc = '1' then
            count <= 0 ;
         elsif  din = '1' then
            count <= delay ;
         elsif 0 < count then
            count <= count - 1 ;
         end if ;
      end if ;
   end process ;
   dout <= '1' when 0 < count else '0' ;
end arc_toff ;

----------------------------------
-- Auto-Repeat system           --
-- Copyright (C) Amos Zaslavsky --
----------------------------------
library ieee ;
use ieee.std_logic_1164.all ;
use ieee.numeric_std.all ;
entity autorepeat is
   generic ( clk_hz    : positive := 50000000 ;
             delay_ms  : positive := 500      ;
             repeat_ms : positive := 200      ) ;
   port ( resetN : in  std_logic ;
          clk    : in  std_logic ;
          din    : in  std_logic ;
          dout   : out std_logic ) ;
end autorepeat ;
architecture arc_autorepeat of autorepeat is
   component ton
      generic (delay      : positive := 50000000) ;
       port ( resetN  : in  std_logic ;
             clk      : in  std_logic ;
             te       : in  std_logic ;
             tout     : out std_logic ) ;
   end component ;
   component xrise
      port ( resetN,clk,din : in  std_logic ;
             dout           : out std_logic ) ;
   end component ;

   component trep
      generic ( delay : integer range
         2 to integer'high := 25000000 ) ;
      port ( resetN  : in  std_logic ;
             clk     : in  std_logic ;
             din     : in  std_logic ;
             dout    : out std_logic ) ;
   end component ;
   signal dint          : std_logic ;
   signal dint_first    : std_logic ;
   signal dint_repeated : std_logic ;
   -- Calculation of delay count
   -- from delay time in milliseconds
   constant timer_delay    : positive
      := (clk_hz/1000) * delay_ms  ;
   constant repeater_delay : positive
      := (clk_hz/1000) * repeat_ms ;
begin
   utimer  : ton
      generic map (delay => timer_delay)
      port map (resetN,clk,din,dint) ;
   urise   : xrise
      port map (resetN,clk,din,dint_first) ;
   urepeat : trep
      generic map (delay => repeater_delay)
      port map (resetN,clk,dint,dint_repeated) ;
   dout <= dint_first or dint_repeated ;
end arc_autorepeat ;

----------------------------------
-- DoubleClick system           --
-- Copyright (C) Amos Zaslavsky --
----------------------------------
library ieee ;
use ieee.std_logic_1164.all ;
use ieee.numeric_std.all ;
entity doubleclick is
   generic ( clk_hz         : positive := 50000000 ;
             doubleclick_ms : positive := 400      ) ;
   port ( resetN : in  std_logic ;
          clk    : in  std_logic ;
          din    : in  std_logic ;
          dout   : out std_logic ) ;
end doubleclick ;
architecture arc_doubleclick of doubleclick is
   component toff
     generic (delay : positive := 50000000 ) ;
      port ( resetN  : in  std_logic ;
             clk     : in  std_logic ;
             din     : in  std_logic ;
             sc      : in  std_logic ;
             dout    : out std_logic ) ;
   end component ;
   component xrise
      port ( resetN,clk,din : in  std_logic ;
             dout           : out std_logic ) ;
   end component ;
   signal dint     : std_logic ;
   signal pulse    : std_logic ;
   signal dout_int : std_logic ;
   -- Calculation of delay count
   -- from delay time in milliseconds
   constant doubleclick_delay : positive
      := (clk_hz/1000) * doubleclick_ms  ;
begin
   urise   : xrise
      port map (resetN,clk,din,dint) ;
   utimer  : toff
      generic map (delay => doubleclick_delay)
      port map (resetN,clk,dint,dout_int,pulse) ;
   dout_int <= pulse and dint ;
   dout <= dout_int ;
end arc_doubleclick ;

---------------------------------------
-- a general switch system top Level --
-- Copyright (C) Amos Zaslavsky      --
---------------------------------------
library ieee ;
use ieee.std_logic_1164.all ;
use ieee.numeric_std.all ;
entity switch is
   generic ( clk_hz         : positive := 50000000 ;
             delay_ms       : positive := 500      ;
             repeat_ms      : positive := 200      ;
             doubleclick_ms : positive := 400      ) ;
   port ( resetN  : in  std_logic ;
          clk     : in  std_logic ;
          din     : in  std_logic ;
          press   : out std_logic ;
          unpress : out std_logic ;
          autorep : out std_logic ;
          double  : out std_logic ) ;
end switch ;
architecture arc_switch of switch is
   component autorepeat
      generic ( clk_hz    : positive := 50000000 ;
                delay_ms  : positive := 500      ;
                repeat_ms : positive := 200      ) ;
      port ( resetN : in  std_logic ;
             clk    : in  std_logic ;
             din    : in  std_logic ;
             dout   : out std_logic ) ;
   end component ;
   component doubleclick
      generic ( clk_hz         : positive := 50000000 ;
                doubleclick_ms : positive := 400      ) ;
      port ( resetN : in  std_logic ;
             clk    : in  std_logic ;
             din    : in  std_logic ;
             dout   : out std_logic ) ;
   end component ;
   component xrise
      port ( resetN,clk,din : in  std_logic ;
             dout           : out std_logic ) ;
   end component ;
   component xfall
      port ( resetN,clk,din : in  std_logic ;
             dout           : out std_logic ) ;
   end component ;
begin
   uautorepeat : autorepeat
      generic map (clk_hz    => clk_hz    ,
                   delay_ms  => delay_ms  ,
                   repeat_ms => repeat_ms )
      port map (resetN,clk,din,autorep) ;
   udoubleclick : doubleclick
      generic map (clk_hz         => clk_hz         ,
                   doubleclick_ms => doubleclick_ms )
      port map (resetN,clk,din,double) ;
   urise : xrise
      port map (resetN,clk,din,press) ;
   ufall : xfall
      port map (resetN,clk,din,unpress) ;
end arc_switch ;
