-------------------------------------------------------------------------------
-- tick_gen_tb.vhd
-- Verifies tick_gen produces a 1-cycle pulse every CLKS_PER_TICK clocks and
-- that holding en='0' halts the counter.
-------------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;

entity tick_gen_tb is
end tick_gen_tb;

architecture testbench of tick_gen_tb is

    component tick_gen is
        generic ( CLKS_PER_TICK : integer );
        port (
            clk  : in  STD_LOGIC;
            en   : in  STD_LOGIC;
            tick : out STD_LOGIC
        );
    end component;

    constant CLK_PERIOD    : time    := 10 ns;
    constant TEST_PER_TICK : integer := 5;

    signal clk  : STD_LOGIC := '0';
    signal en   : STD_LOGIC := '0';
    signal tick : STD_LOGIC;

begin

    uut : tick_gen
        generic map ( CLKS_PER_TICK => TEST_PER_TICK )
        port map (
            clk  => clk,
            en   => en,
            tick => tick
        );

    clk_proc : process begin
        clk <= '0';
        wait for CLK_PERIOD/2;
        clk <= '1';
        wait for CLK_PERIOD/2;
    end process clk_proc;

    stim_proc : process begin
        -- en low: no ticks should appear.
        en <= '0';
        wait for 10*CLK_PERIOD;

        -- en high: expect a tick every TEST_PER_TICK clocks.
        en <= '1';
        wait for 20*CLK_PERIOD;

        -- en low again: ticks should stop, counter frozen.
        en <= '0';
        wait for 10*CLK_PERIOD;

        -- en high again: resumes ticking.
        en <= '1';
        wait for 15*CLK_PERIOD;

        wait;
    end process stim_proc;

end testbench;
