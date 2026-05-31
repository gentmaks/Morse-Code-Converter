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
        port (
            clk             : in  std_logic;
            reset           : in  std_logic;

            start_playback  : in  std_logic;
            unit_tick       : in  std_logic;

            morse_data      : in  std_logic_vector(18 downto 0);
            length_data     : in  std_logic_vector(4 downto 0);

            morse_on        : out std_logic;
            playback_done   : out std_logic
        );
    end component;

    signal clk            : std_logic := '0';
    signal reset          : std_logic := '0';
    signal start_playback : std_logic := '0';
    signal unit_tick      : std_logic := '0';
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
        port map (
        clk            => clk,
        reset          => reset,
        start_playback => start_playback,
        unit_tick      => unit_tick,
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
    -- One T-unit helper
    --=========================================================

    tick_process: process
    begin
        wait;
    end process tick_process;


    --=========================================================
    -- Stimulus
    --=========================================================

    stim_process: process

        procedure send_start is
        begin
            start_playback <= '1';
            wait for clk_period;
            start_playback <= '0';
        end procedure;

        procedure send_tick is
        begin
            wait for 4 * clk_period;
            unit_tick <= '1';
            wait for clk_period;
            unit_tick <= '0';
        end procedure;

    begin

        -- Reset
        reset <= '1';
        start_playback <= '0';
        unit_tick <= '0';
        morse_data <= (others => '0');
        length_data <= (others => '0');
        wait for 3 * clk_period;

        reset <= '0';
        wait for 2 * clk_period;


        --=====================================================
        -- Test 1: E = .
        -- Pattern: 1
        -- Length: 1
        --=====================================================

        morse_data  <= "1000000000000000000";
        length_data <= "00001";
        send_start;

        send_tick;
        wait for 5 * clk_period;


        --=====================================================
        -- Test 2: A = .-
        -- Pattern: 1 0 1 1 1
        -- Length: 5
        --=====================================================

        morse_data  <= "1011100000000000000";
        length_data <= "00101";
        send_start;

        send_tick;
        send_tick;
        send_tick;
        send_tick;
        send_tick;
        wait for 5 * clk_period;


        --=====================================================
        -- Test 3: B = -...
        -- Pattern: 1 1 1 0 1 0 1 0 1
        -- Length: 9
        --=====================================================

        morse_data  <= "1110101010000000000";
        length_data <= "01001";
        send_start;

        send_tick;
        send_tick;
        send_tick;
        send_tick;
        send_tick;
        send_tick;
        send_tick;
        send_tick;
        send_tick;
        wait for 5 * clk_period;


        --=====================================================
        -- Test 4: Number 5 = .....
        -- Pattern: 1 0 1 0 1 0 1 0 1
        -- Length: 9
        --=====================================================

        morse_data  <= "1010101010000000000";
        length_data <= "01001";
        send_start;

        send_tick;
        send_tick;
        send_tick;
        send_tick;
        send_tick;
        send_tick;
        send_tick;
        send_tick;
        send_tick;
        wait for 5 * clk_period;


        --=====================================================
        -- Test 5: Number 0 = -----
        -- Pattern: 1110111011101110111
        -- Length: 19
        --=====================================================

        morse_data  <= "1110111011101110111";
        length_data <= "10011";
        send_start;

        send_tick;
        send_tick;
        send_tick;
        send_tick;
        send_tick;
        send_tick;
        send_tick;
        send_tick;
        send_tick;
        send_tick;
        send_tick;
        send_tick;
        send_tick;
        send_tick;
        send_tick;
        send_tick;
        send_tick;
        send_tick;
        send_tick;
        wait for 10 * clk_period;


        -- End simulation
        wait;

    end process stim_process;

end testbench;