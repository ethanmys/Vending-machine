----------------------------------------------------------------------------------
--Name: Chuan Lim Kho
---- Design Overview: Emulation of a vending machine using a state machine
-- Design name: project 5
-- DESCRIPTION OF PROJECT
-- Basically this state machine has 4 states
--idle-during start up or no coint inserted
--rm-- It is the state where coin is inserted while waiting for input selection from button
--dp- This is the state after selection button is pressed, it will determine whether it has sufficient money, 
--if not, it would go back to RM state
--wait-- this is the state where it illuminate for 1 second before going to idle state

----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;


entity Projec5 is
port(
		clk50: in std_logic;
		pushbutton: in std_logic_vector(3 downto 0);
		sliderswitches: in std_logic_vector(3 downto 0);
		seg7: out std_logic_vector(7 downto 0);
		leds:out std_logic_vector(2 downto 0):="000";
		anode: out std_logic_vector(3 downto 0)
		);
end Projec5;

architecture Behavioral of Projec5 is
signal intclk: std_logic :='0'; --- internal clk signal
signal dig1,dig2,dig3,dig4: std_logic_vector(3 downto 0):="0000"; --signal from debounce to 7seg
signal HEX: STD_LOGIC_VECTOR (3 downto 0); --input for 7seg
signal count: unsigned(7 downto 0);
signal disp: unsigned(7 downto 0); --display to the 7seg signal
signal slider,slider1,slider2: std_logic :='0';
signal btn,btn1,btn2:std_logic:='0';
signal valid: std_logic;
signal bcd_sig: unsigned(7 downto 0);
signal resetcount:Std_logic;
signal waittime,next_waittime:unsigned(9 downto 0);
--------------
type fsmd_state_type is (idle,rm,dp,wait1);
signal state_reg, state_next:fsmd_state_type;
-----
begin
---ASM
process(intclk,sliderswitches)
begin
	if (sliderswitches(3)='1') then 
			state_reg<=idle;
			waittime<=(others=>'0');
	elsif(intclk'event and intclk='1') then
			state_reg<=state_next;
			waittime<=next_waittime;
	end if;
end process;
--next state logic--
process(state_reg,slider,slider1,slider2,btn,btn1,btn2,valid,intclk,waittime)
begin
	case state_reg is
		when idle=>
			if slider='1' or slider1='1' or slider2='1' then 
				state_next<=rm;
			else
				state_next<=idle;
			end if;
			next_waittime<=(others=>'0');
		when rm=>
			if btn='1' or btn1='1' or btn2='1' then 
				state_next<=dp;
			else
				state_next<=rm;
			end if;
			next_waittime<=(others=>'0');
		when dp=>
			if valid='1' then 
				state_next<=wait1;
			else
				state_next<=rm;
			end if;
			next_waittime<=(others=>'0');
		when wait1=>
			if waittime=1000 then
				state_next<=idle;
			else 
				state_next<=wait1;
				next_waittime<=waittime+1;
			end if;
		when others=>
			state_next<=idle;
	end case;
end process;

--output logic
process(state_reg,btn,btn1,btn2,valid,count)
variable counter:integer:=0;
begin 
	case state_reg is 
		when idle=>
			disp<="00000000";
			leds(0)<='0';
			leds(1)<='0';
			leds(2)<='0';
			resetcount<='0';
		when rm=>
			disp<=count;
		when dp=>
			if valid='1' and btn='1' then
				leds(0)<='1';

			elsif valid='1' and btn1='1' then
				leds(1)<='1';

			elsif valid='1' and btn2='1' then
				leds(2)<='1';
			else
				leds(0)<='0';
				leds(1)<='0';
				leds(2)<='0';
			end if;		
		when wait1=>
				disp<="00000000";
				resetcount<='1';
		when others=>
			disp<="00000000";
			leds(0)<='0';
			leds(1)<='0';
			leds(2)<='0';
			resetcount<='0';
				
	end case;
end process;
------

-- debounce circuit
process(sliderswitches,pushbutton,intclk)
variable cnt: integer:=0; --for debounce circuit
begin
if (intclk'EVENT AND intclk = '1') then
	if sliderswitches(0)='1' and cnt=50 then
			slider<='1';
			cnt := 0;
	elsif sliderswitches(1)='1' and cnt=50 then
			slider1<='1';
			cnt := 0;	
	elsif sliderswitches(2)='1' and cnt=50 then
			slider2<='1';
			cnt := 0;
	elsif pushbutton(0)='1' and cnt=50 then
			btn<='1';
			cnt:=0;
	elsif pushbutton(1)='1' and cnt=50 then
			btn1<='1';
			cnt:=0;
	elsif pushbutton(2)='1' and cnt=50 then
			btn2<='1';
			cnt:=0;
	elsif cnt /=51 and (sliderswitches(0)='1' or sliderswitches(1)='1' or sliderswitches(2)='1' or pushbutton(0)='1' or pushbutton(1)='1' or pushbutton(2)='1') THEN 
			cnt := cnt + 1;
	else
			slider<='0';
			slider1<='0';
			slider2<='0';
			btn<='0';
			btn1<='0';
			btn2<='0';
	end if;
	
end if;

end process;



--- to detect toggling of sliderswitches---
process(sliderswitches,slider,clk50,resetcount,pushbutton)
variable cnt: integer:=0; --for debounce circuit
variable detect : std_ulogic_vector (1 downto 0):="00";
variable detect1 : std_ulogic_vector (1 downto 0):="00";
variable detect2 : std_ulogic_vector (1 downto 0):="00";

begin

if sliderswitches(3)='1' or resetcount='1' or pushbutton(3)='1' then
			count<=(others=>'0');         
elsif (rising_edge(clk50)) then
         detect(1) := detect(0); -- record last value of sync in detect(1)
         detect(0) := slider ; --record current sync in detect(0)
			detect1(1) := detect1(0); -- record last value of sync in detect(1)
         detect1(0) := slider1 ; 
			detect2(1) := detect2(0); -- record last value of sync in detect(1)
         detect2(0) := slider2 ; 
	if detect="01" then
		if count <=90 then
			count<=count+5;
			cnt := 0;
		else 
			count<="01011111";
		end if;
	elsif detect1="01" then 
		if count <=85 then
			count<=count+10;
			cnt := 0;
		else
			count<="01011111";
		end if;
	elsif detect2="01" then 
		if count <=70 then
			count<=count+25;
			cnt := 0;
		else 
			count <="01011111";
		end if;
	else
			count<=count;
	end if;	
else
			cnt:=0;

end if;

end process;
----------------------------------------------
------------pushbutton operation--------
process(btn,btn1,btn2,count,intclk)

begin
if rising_edge(intclk) then
	if btn='1' then

		if count>=55 then
			valid<='1';

		else
			valid<='0';
		end if;
	elsif btn1='1'  then
		if count>=70  then
			valid<='1';

		else
			valid<='0';
		end if;
	elsif btn2='1' then
		if count>=75 then
			valid<='1';
		else
			valid<='0';
		end if;
	else
			valid<='0';
	end if;
end if;

end process;
--------------to change to BCD----------------
  bcd1: process(disp)

  variable z: unsigned (17 downto 0);
	variable bina:unsigned(7 downto 0);
  begin
	bina:=disp(7)&disp(6)&disp(5)&disp(4)&disp(3)&disp(2)&disp(1)&disp(0);
    	for i in 0 to 17 loop
		z(i) := '0';
    	end loop;
 		z(10 downto 3) := bina;
    	for i in 0 to 4 loop
		if z(11 downto 8) > "0100" then	
		   	z(11 downto 8) := z(11 downto 8) + "0011";
		end if;
		if z(15 downto 12) > "0100" then	
		   	z(15 downto 12) := z(15 downto 12) + "0011";
		end if;
		z(17 downto 1) := z(16 downto 0);
    	end loop;
	bcd_sig <= z(15)&z(14)&z(13)&z(12)&z(11)&z(10)&z(9)&z(8);	
  end process bcd1;            


---------------50 Mhz to 1khz clock----------------
divclk:process(clk50)
variable counter:integer:=0;
begin
   if clk50'event and clk50='1' then  
		counter:=counter+1;
		if counter=50000 then
			intclk<= not intclk;
			counter:=0;
		end if;
	end if;
end process divclk;
----------------------------------------------------
-----------------------------------------------------

----for 7 segment display-----
Process(intclk,bcd_sig) 
variable c: integer range 0 to 3; 
begin 
dig1<=bcd_sig(3)&bcd_sig(2)&bcd_sig(1)&bcd_sig(0);
dig2<=bcd_sig(7)&bcd_sig(6)&bcd_sig(5)&bcd_sig(4);
If intclk'event and intclk='1' then 
	if c= 3 then
		c:=0;
	else	
		c:=c+1;
	end if;

case c is
	when 0 => anode<="1110";
		HEX<=dig1;
	when 1 => anode<="1101";
		HEX<=dig2;
	when 2 => anode<="1011";
		HEX<=dig3;
	when 3 => anode<="0111";
		HEX<=dig4;
	end case;
end if;
end process;
--HEX-to-seven-segment decoder
--   HEX:   in    STD_LOGIC_VECTOR (3 downto 0);
--   seg7:   out   STD_LOGIC_VECTOR (7 downto 0);
-- 
-- segment encoinputg
--      0
--     ---  
--  5 |   | 1
--     ---   <- 6
--  4 |   | 2
--     ---
--      3
   
    with HEX SELect
   seg7<="11111001" when "0001",   --1
         "10100100" when "0010",   --2
         "10110000" when "0011",   --3
         "10011001" when "0100",   --4
         "10010010" when "0101",   --5
         "10000010" when "0110",   --6
         "11111000" when "0111",   --7
         "10000000" when "1000",   --8
         "10010000" when "1001",   --9
         "10001000" when "1010",   --A
         "10000011" when "1011",   --b
         "11000110" when "1100",   --C
         "10100001" when "1101",   --d
         "10000110" when "1110",   --E
         "10001110" when "1111",   --F
         "11000000" when others;   --0

end behavioral;