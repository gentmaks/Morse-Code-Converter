-------------------------------------------------------------------------------
-- SCI_tx.vhd
-- Authors: Gent Maksutaj, Papa Yaw Owusu Nti
-------------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

ENTITY SCI_tx is
    generic (
        Baud_period : integer := 10417
            );
    PORT (
        clk : in STD_LOGIC;
        Parallel_in : in STD_LOGIC_VECTOR(7 downto 0);
        New_data : in STD_LOGIC;
        Tx : out STD_LOGIC
    );
end SCI_tx;


ARCHITECTURE behavioral of SCI_tx is

signal shift_reg : STD_LOGIC_VECTOR(9 downto 0) := (others => '1');
signal baud_counter: UNSIGNED(14 downto 0) := (others => '0');
signal tc: STD_LOGIC;

begin

tc <= '1' when baud_counter = Baud_period - 1 else '0';

--datapath process updates the baud_counter and shifts the values
datapath: process(clk) begin

    if rising_edge(clk) then
        baud_counter <= baud_counter + 1;
        if (tc = '1' or New_data = '1') then
            baud_counter <= (others => '0');
        end if;
        if (New_data = '1') then
            shift_reg <= '1' & Parallel_in & '1'; -- Concatenating with start and end bit
        elsif (tc = '1') then
            shift_reg <= '1' & shift_reg(9 downto 1); -- Shifting + Idle bit
        end if;
    end if;
end process datapath;

-- Serial Output
Tx <= shift_reg(0);

end behavioral;
