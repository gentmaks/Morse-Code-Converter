-------------------------------------------------------------------------------
-- scheduler_tb.vhd
-- Exercises every branch of the Playback Scheduler FSM:
--   * first char (need_gap=0)            -> START_PLAY directly
--   * playable char (need_gap=1)         -> LETTER_GAP -> START_PLAY
--   * space with need_gap=1              -> WORD_GAP (clears need_gap)
--   * space with need_gap=0              -> skipped back to IDLE
--   * empty FIFO                          -> IDLE hold
-- t_tick is driven fast so gaps complete quickly in simulation.
-------------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;

entity Scheduler_tb is
end Scheduler_tb;

architecture testbench of Scheduler_tb is

    component Scheduler is
        port (
            clk            : in  STD_LOGIC;
            t_tick         : in  STD_LOGIC;
            fifo_empty     : in  STD_LOGIC;
            char_in        : in  STD_LOGIC_VECTOR(7 downto 0);
            playback_done  : in  STD_LOGIC;
            fifo_read      : out STD_LOGIC;
            current_char   : out STD_LOGIC_VECTOR(7 downto 0);
            start_playback : out STD_LOGIC
        );
    end component;

    -- Inputs
    signal clk           : STD_LOGIC := '0';
    signal t_tick        : STD_LOGIC := '0';
    signal fifo_empty    : STD_LOGIC := '1';
    signal char_in       : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
    signal playback_done : STD_LOGIC := '0';

    -- Outputs
    signal fifo_read      : STD_LOGIC;
    signal current_char   : STD_LOGIC_VECTOR(7 downto 0);
    signal start_playback : STD_LOGIC;

    constant CLK_PERIOD : time := 10 ns; -- 100 MHz

    -- ASCII codes
    constant CH_E     : STD_LOGIC_VECTOR(7 downto 0) := x"45"; -- 'E'
    constant CH_T     : STD_LOGIC_VECTOR(7 downto 0) := x"54"; -- 'T'
    constant CH_SPACE : STD_LOGIC_VECTOR(7 downto 0) := x"20"; -- ' '

begin

    uut : Scheduler
        port map (
        clk            => clk,
        t_tick         => t_tick,
        fifo_empty     => fifo_empty,
        char_in        => char_in,
        playback_done  => playback_done,
        fifo_read      => fifo_read,
        current_char   => current_char,
        start_playback => start_playback
        );

    -- Clock
    clk_proc : process begin
        clk <= '0';
        wait for CLK_PERIOD/2;
        clk <= '1';
        wait for CLK_PERIOD/2;
    end process clk_proc;

    -- Fast T-unit tick: one-cycle pulse every 4 clocks.
    tick_proc : process
    begin
        t_tick <= '0';

        wait for 3*CLK_PERIOD;

        wait until rising_edge(clk);
        t_tick <= '1';

        wait until rising_edge(clk);
        t_tick <= '0';
    end process tick_proc;
    -- Stimulus
    stim_proc : process

        -- Present one character at the FIFO head, wait for the scheduler to read
        -- it (fifo_read pulse), then drop fifo_empty as if the FIFO drained.
        procedure present_char(constant b : STD_LOGIC_VECTOR(7 downto 0)) is
        begin
            char_in    <= b;
            fifo_empty <= '0';
            wait until rising_edge(clk) and fifo_read = '1';
            wait until rising_edge(clk);
            fifo_empty <= '1';
        end procedure;

        -- Acknowledge playback once start_playback has fired.
        procedure finish_playback is
        begin
            wait until rising_edge(clk) and start_playback = '1';
            wait for 5*CLK_PERIOD;
            wait until rising_edge(clk);
            playback_done <= '1';
            wait until rising_edge(clk);
            playback_done <= '0';
        end procedure;

    begin
        -- Reset settle
        wait for 5*CLK_PERIOD;

        -- 1) First char 'E': need_gap=0 -> START_PLAY directly (no gap).
        present_char(CH_E);
        finish_playback;

        -- 2) Char 'T': need_gap=1 -> LETTER_GAP (3T) -> START_PLAY.
        present_char(CH_T);
        finish_playback;

        -- 3) Space with need_gap=1 -> WORD_GAP (7T), clears need_gap.
        present_char(CH_SPACE);
        wait for 30*CLK_PERIOD; -- let word gap elapse

        -- 4) Space with need_gap=0 -> skipped straight back to IDLE.
        present_char(CH_SPACE);
        wait for 10*CLK_PERIOD;

        -- 5) Char 'E' after the word gap: need_gap=0 -> START_PLAY directly.
        present_char(CH_E);
        finish_playback;

        -- 6) Empty FIFO: scheduler should sit in IDLE.
        fifo_empty <= '1';
        wait for 20*CLK_PERIOD;

        wait;
    end process stim_proc;

end testbench;