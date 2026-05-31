--------------------------------------------------------------------------------
-- Authors: Gent Maksutaj, Papa Yaw Owusu Nti
-- Course:   Engs 31 25S
-- Final Project (Morse Code Converter)
-- Module Name: tick_gen.vhd
--------------------------------------------------------------------------------
-- Parameterizable clock-enable / tick generator.
-- Runs off the single 100 MHz system clock and emits a 1-cycle 'tick' pulse
-- every CLKS_PER_TICK clock cycles. Downstream counters advance only on these
-- ticks, so we never create a second clock domain. Override the generic with a
-- small value in simulation to make ticks happen quickly.
--------------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity tick_gen is
    generic (
        CLKS_PER_TICK : integer := 10_000_000 -- 1 T-unit = 100 ms @ 100 MHz
    );
    port (
        clk  : in  STD_LOGIC;
        en   : in  STD_LOGIC; -- gate; tie '1' for free-running
        tick : out STD_LOGIC  -- high for exactly one clk every CLKS_PER_TICK cycles
    );
end tick_gen;

architecture behavioral of tick_gen is

    signal count    : unsigned(31 downto 0) := (others => '0');
    signal tick_sig : STD_LOGIC := '0';

begin

    counter : process(clk) begin
        if rising_edge(clk) then
            tick_sig <= '0';
            if en = '1' then
                if count = CLKS_PER_TICK - 1 then
                    count    <= (others => '0');
                    tick_sig <= '1';
                else
                    count <= count + 1;
                end if;
            end if;
        end if;
    end process counter;

    tick <= tick_sig;

end behavioral;
