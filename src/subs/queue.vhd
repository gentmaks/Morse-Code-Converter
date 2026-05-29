-------------------------------------------------------------------------------
-- queue.vhd
-------------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

ENTITY Queue IS
PORT ( 	clk		:	in	STD_LOGIC; --10 MHz clock
		Write	: 	in 	STD_LOGIC;
		Read	: 	in 	STD_LOGIC;
        Data_in	:	in	STD_LOGIC_VECTOR(7 downto 0);
		Data_out:	out	STD_LOGIC_VECTOR(7 downto 0);
        Empty	:	out	STD_LOGIC;
        Full	:	out	STD_LOGIC);
end Queue;


architecture behavior of Queue is

CONSTANT QUEUE_LENGTH : integer := 8;

type regfile is array(0 to QUEUE_LENGTH-1) of STD_LOGIC_VECTOR(7 downto 0);
signal Queue_reg : regfile := (others =>(others => '0'));

signal W_ADDR : integer := 0;
signal R_ADDR : integer := 0;
signal Element_cnt : integer := 0;
signal Full_sig, Empty_sig : std_logic := '0';

BEGIN

process(clk, Element_cnt)
begin
	if rising_edge(clk) then
    
    --Basic Queue Logic
    	if (Write = '1') and (Full_sig = '0') then
        	Queue_reg(W_ADDR) <= Data_in;
            if W_ADDR = QUEUE_LENGTH-1 then
            	W_ADDR <= 0;
      		else
            	W_ADDR <= W_ADDR + 1;
            end if;
        end if;
        
        if (read = '1') and (Empty_sig = '0') then
        	Queue_reg(R_ADDR) <= (others => '0');
        	if R_ADDR = QUEUE_LENGTH-1 then
            	R_ADDR <= 0;
      		else
            	R_ADDR <= R_ADDR + 1;
            end if;
        end if;
        
        
        --Keep track of number of elements to signal Empty or Full. Note that this could easily be embedded into the if/else statements above. I just wanted to make it clear that this counter is separate hardware.
        if (Write = '1') and (Full_sig = '0') then
        	Element_cnt <= Element_cnt + 1;
        elsif (read = '1') and (Empty_sig = '0') then
        	Element_cnt <= Element_cnt - 1;
        end if;
    end if;
    
    --Comparitors for Full_sig and Empty_sig
    Full_sig <= '0';
    Empty_sig <= '0';
    if Element_cnt = QUEUE_LENGTH then
    	Full_sig <= '1';
    elsif Element_cnt = 0 then
    	Empty_sig <= '1';
    end if;
        
end process;

Full <= Full_sig;
Empty <= Empty_sig;
Data_out <= Queue_reg(R_ADDR);

end behavior;
