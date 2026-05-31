-------------------------------------------------------------------------------
-- encoder_tb.vhd
-------------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;

ENTITY SPI_rx_tb is
end SPI_rx_tb;

ARCHITECTURE testbench of SPI_rx_tb is

COMPONENT Serial_Receiver IS
    GENERIC (
        Baud_period : integer
            );
    PORT ( 	
            clk		       :	in	STD_LOGIC;
            RsRx	       : 	in 	STD_LOGIC;
            rx_shift	   : 	out STD_LOGIC;
            rx_data	       :	out	STD_LOGIC_VECTOR(7 downto 0);
            rx_done_tick   :	out	STD_LOGIC
    );

end COMPONENT;

-- Inputs
signal clk : STD_LOGIC := '0';
signal RsRx : STD_LOGIC := '0';

-- Outputs
signal rx_shift : STD_LOGIC;
signal rx_data : STD_LOGIC_VECTOR;
signal rx_done_tick : STD_LOGIC;

BEGIN

uut: Serial_Receiver
    GENERIC MAP (
        Baud_period => -- TODO
    );
    PORT MAP (
        clk => clk;
        RsRx => RsRx;
        rx_shift => rx_shift;
        rx_data => rx_data;
        rx_done_tick => rx_done_tick;
    );

-- Clock process
    clk_process: process
    begin
        -- TODO
    end process;

-- Stimulus process
    stim_process: process
    begin
        -- TODO
    end process;

end testbench;
