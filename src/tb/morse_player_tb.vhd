--=============================================================
-- Morse Player Testbench
-- Tests one encoded Morse character at a time
-- Authors: Gent Maksutaj, Papa Yaw Owusu Nti
--=============================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity morse_player_tb is
end morse_player_tb;

architecture testbench of morse_player_tb is

    component morse_player is
        generic (
            UNIT_COUNT : integer := 10000000
        );
        port (
            clk             : in  std_logic;
            reset           : in  std_logic;

            start_playback  : in  std_logic;
            morse_data      : in  std_logic_vector(18 downto 0);
            length_data     : in  std_logic_vector(4 downto 0);

            morse_on        : out std_logic;
            playback_done   : out std_logic
        );
    end component;

    signal clk            : std_logic := '0';
    signal reset          : std_logic := '0';
    signal start_playback : std_logic := '0';
    signal morse_data     : std_logic_vector(18 downto 0) := (others => '0');
    signal length_data    : std_logic_vector(4 downto 0) := (others => '0');
    signal morse_on       : std_logic;
    signal playback_done  : std_logic;

    constant clk_period : time := 10 ns;

begin

    --=========================================================
    -- Unit under test
    --=========================================================

    uut: morse_player
        generic map (
        UNIT_COUNT => 4
        )
        port map (
        clk            => clk,
        reset          => reset,
        start_playback => start_playback,
        morse_data     => morse_data,
        length_data    => length_data,
        morse_on       => morse_on,
        playback_done  => playback_done
        );


    --=========================================================
    -- Clock
    --=========================================================

    clk_process: process
    begin
        clk <= '0';
        wait for clk_period / 2;

        clk <= '1';
        wait for clk_period / 2;
    end process clk_process;


    --=========================================================
    -- Stimulus
    --=========================================================

    stim_process: process
    begin

        -- Reset
        reset <= '1';
        start_playback <= '0';
        morse_data <= (others => '0');
        length_data <= (others => '0');
        wait for 3 * clk_period;

        reset <= '0';
        wait for 2 * clk_period;


        --=====================================================
        -- Test 1: E = .
        -- Pattern: 1
        -- Length: 1
        -- Expected: morse_on high for one T-unit
        --=====================================================

        morse_data  <= "1000000000000000000";
        length_data <= "00001";

        start_playback <= '1';
        wait for clk_period;
        start_playback <= '0';

        wait for 15 * clk_period;


        --=====================================================
        -- Test 2: A = .-
        -- Pattern: 1 0 1 1 1
        -- Length: 5
        -- Expected: ON, OFF, ON, ON, ON
        --=====================================================

        morse_data  <= "1011100000000000000";
        length_data <= "00101";

        start_playback <= '1';
        wait for clk_period;
        start_playback <= '0';

        wait for 35 * clk_period;


        --=====================================================
        -- Test 3: B = -...
        -- Pattern: 1 1 1 0 1 0 1 0 1
        -- Length: 9
        -- Expected: dash, gap, dot, gap, dot, gap, dot
        --=====================================================

        morse_data  <= "1110101010000000000";
        length_data <= "01001";

        start_playback <= '1';
        wait for clk_period;
        start_playback <= '0';

        wait for 55 * clk_period;


        --=====================================================
        -- Test 4: Number 5 = .....
        -- Pattern: 1 0 1 0 1 0 1 0 1
        -- Length: 9
        -- Expected: five dots separated by one-unit gaps
        --=====================================================

        morse_data  <= "1010101010000000000";
        length_data <= "01001";

        start_playback <= '1';
        wait for clk_period;
        start_playback <= '0';

        wait for 55 * clk_period;


        --=====================================================
        -- Test 5: Number 0 = -----
        -- Longest pattern
        -- Pattern: 111 0 111 0 111 0 111 0 111
        -- Length: 19
        -- Expected: five dashes separated by one-unit gaps
        --=====================================================

        morse_data  <= "1110111011101110111";
        length_data <= "10011";

        start_playback <= '1';
        wait for clk_period;
        start_playback <= '0';

        wait for 100 * clk_period;


        -- End simulation
        wait;

    end process stim_process;

end testbench;