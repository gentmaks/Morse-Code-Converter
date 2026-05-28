-------------------------------------------------------------------------------
-- queue_tb.vhd
-------------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;

entity Queue_tb is
end Queue_tb;

architecture testbench of Queue_tb is

component Queue IS
PORT ( 	clk		:	in	STD_LOGIC; --10 MHz clock
		Write	: 	in 	STD_LOGIC;
		read	: 	in 	STD_LOGIC;
        Data_in	:	in	STD_LOGIC_VECTOR(7 downto 0);
		Data_out:	out	STD_LOGIC_VECTOR(7 downto 0));
end component;



signal 	clk		:	STD_LOGIC; --10 MHz clock
signal 	Write	: 	STD_LOGIC 	:= '0';
signal 	Read	: 	STD_LOGIC	:= '0';
signal 	Data_in	:	STD_LOGIC_Vector(7 downto 0) := "00000000";
signal 	Data_out:	STD_LOGIC_Vector(7 downto 0) := "00000000";


begin

uut : Queue PORT MAP(
		clk  => CLK,
		Read => Read,
        Write => Write,
        Data_in => Data_in,
		Data_out => Data_out);
    
    
clk_proc : process
BEGIN

  CLK <= '0';
  wait for 5ns;   

  CLK <= '1';
  wait for 5ns;

END PROCESS clk_proc;

stim_proc : process
begin
	
    wait for 10 ns;
    
    Data_in <= "11110000";--0xF0
    Write <= '1';
    Wait for 10 ns;
    Write <= '0';
    
    wait for 40 ns;
    Data_in <= "00001111";--0x0F
    Write <= '1';
    wait for 10 ns;
    write <= '0';
    
    wait for 40 ns;
    Data_in <= "10101010";--0xAA
    Write <= '1';
    wait for 10 ns;
    write <= '0';
  
  	wait for 40 ns;
    Data_in <= "01010011";--0x53
    Write <= '1';
    wait for 10 ns;
    write <= '0';
    
    wait for 40 ns;
    Data_in <= "11010010";--0xD2
    Write <= '1';
    wait for 10 ns;
    write <= '0';
    
    wait for 40 ns;
    Data_in <= "11111111";--0xFF
    Write <= '1';
    wait for 10 ns;
    write <= '0';
    
    wait for 40 ns;
    Data_in <= "00110001";--0x31
    Write <= '1';
    wait for 10 ns;
    write <= '0';
    
    wait for 40 ns;
    Data_in <= "01010101";--0x55
    Write <= '1';
    wait for 10 ns;
    write <= '0';
    
    wait for 40 ns;
    Data_in <= "10001100";--0x8C  --The queue should be full and this should not get stored
    Write <= '1';
    wait for 10 ns;
    write <= '0';
   
    wait for 40 ns; -- Read once
    read <= '1';
    wait for 10 ns;
    read <= '0';
	
    wait for 40 ns; -- Read once
    read <= '1';
    wait for 10 ns;
    read <= '0';
    
    wait for 40 ns;
    Data_in <= "11000111";--0xC7
    Write <= '1';
    wait for 10 ns;
    write <= '0';
  
  	wait for 40 ns;
    Data_in <= "00000001";--0x01
    Write <= '1';
    wait for 10 ns;
    write <= '0';
    
    wait for 40 ns; -- Read once
    read <= '1';
    wait for 10 ns;
    read <= '0';
	
    wait for 40 ns; -- Read once
    read <= '1';
    wait for 10 ns;
    read <= '0';
    
    wait for 40 ns; -- Read once
    read <= '1';
    wait for 10 ns;
    read <= '0';
	
    wait for 40 ns; -- Read once
    read <= '1';
    wait for 10 ns;
    read <= '0';
    
    wait for 40 ns; -- Read once
    read <= '1';
    wait for 10 ns;
    read <= '0';
    
    wait for 40 ns; -- Read once
    read <= '1';
    wait for 10 ns;
    read <= '0';
    
    wait for 40 ns; -- Read once
    read <= '1';
    wait for 10 ns;
    read <= '0';
    
    wait for 40 ns; -- Read once
    read <= '1';
    wait for 10 ns;
    read <= '0';
    
    wait for 40 ns; -- Read once --tbe queue is already empty, so this should do nothing.
    read <= '1';
    wait for 10 ns;
    read <= '0';
    
    wait for 40 ns;
    Data_in <= "11111111";--0xFF
    Write <= '1';
    wait for 10 ns;
    write <= '0';
    
    wait;
end process stim_proc;
end testbench;
