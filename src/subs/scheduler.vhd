--------------------------------------------------------------------------------
-- Authors: Gent Maksutaj, Papa Yaw Owusu Nti
-- Course:   Engs 31 25S
-- Final Project (Morse Code Converter)
-- Module Name: scheduler.vhd
--------------------------------------------------------------------------------
-- Playback Scheduler FSM + datapath.
-- Reads characters from the FIFO, decides whether each character is a space or a
-- playable symbol, inserts the correct letter/word gap, and tells the Morse
-- Player when to start.
--
-- Gap timing is measured in T-units. The base T-unit pulse (t_tick) is produced
-- by an external tick_gen instance and shared with the Morse Player.
--   letter gap = 3 T-units, word gap = 7 T-units.
--------------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity Scheduler is
    port (
        clk            : in  STD_LOGIC;
        t_tick         : in  STD_LOGIC;                    -- T-unit pulse (gap timing base)
        fifo_empty     : in  STD_LOGIC;                    -- Queue.Empty
        char_in        : in  STD_LOGIC_VECTOR(7 downto 0); -- Queue.Data_out
        playback_done  : in  STD_LOGIC;                    -- Morse Player
        fifo_read      : out STD_LOGIC;                    -- Queue.Read
        current_char   : out STD_LOGIC_VECTOR(7 downto 0); -- Character Encoder
        start_playback : out STD_LOGIC                     -- Morse Player
    );
end Scheduler;

architecture behavioral of Scheduler is

    -- Gap targets (in T-units)
    constant LETTER_GAP_UNITS : integer := 3;
    constant WORD_GAP_UNITS   : integer := 7;

    constant SPACE_CHAR : STD_LOGIC_VECTOR(7 downto 0) := x"20";

    -- FSM states
    type state_type is (
        IDLE,
        READ_CHAR,
        CHECK_CHAR,
        LETTER_GAP,
        WORD_GAP,
        START_PLAY,
        WAIT_PLAY
    );

    signal curr_state, next_state : state_type := IDLE;

    -- FSM datapath control outputs
    signal char_load    : STD_LOGIC := '0'; -- store FIFO output into current_char register
    signal gap_en       : STD_LOGIC := '0'; -- enable the gap timer
    signal gap_sel      : STD_LOGIC := '0'; -- '0' = letter gap, '1' = word gap
    signal need_gap_set : STD_LOGIC := '0'; -- remember a character has been started/played
    signal need_gap_clr : STD_LOGIC := '0'; -- clear the need_gap flag after a word gap
    signal fifo_read_sig: STD_LOGIC := '0';
    signal start_pb_sig : STD_LOGIC := '0';

    -- FSM datapath status inputs
    signal is_space : STD_LOGIC := '0';
    signal need_gap : STD_LOGIC := '0';
    signal gap_done : STD_LOGIC := '0';

    -- Datapath registers
    signal char_reg : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
    signal gap_cnt  : unsigned(3 downto 0) := (others => '0'); -- up to 7 T-units

begin

    -----------------------------------------------------------------------
    -- Controller: State Update
    -----------------------------------------------------------------------
    StateUpdate : process(clk) begin
        if rising_edge(clk) then
            curr_state <= next_state;
        end if;
    end process StateUpdate;

    -----------------------------------------------------------------------
    -- Controller: Next State Logic
    -----------------------------------------------------------------------
    NextStateLogic : process(curr_state, fifo_empty, is_space, need_gap,
                             gap_done, playback_done) begin
        next_state <= curr_state;

        case (curr_state) is

            when IDLE =>
                -- Wait for a character to be available in the FIFO.
                if (fifo_empty = '0') then
                    next_state <= READ_CHAR;
                end if;

            when READ_CHAR =>
                -- One-cycle state: read from FIFO and latch into current_char.
                next_state <= CHECK_CHAR;

            when CHECK_CHAR =>
                -- Classify the loaded character and route accordingly.
                if (is_space = '0' and need_gap = '0') then
                    next_state <= START_PLAY;          -- first/playable char, no gap needed
                elsif (is_space = '0' and need_gap = '1') then
                    next_state <= LETTER_GAP;          -- playable char preceded by another
                elsif (is_space = '1' and need_gap = '1') then
                    next_state <= WORD_GAP;            -- real space between words
                else
                    next_state <= IDLE;                -- leading/duplicate space: skip
                end if;

            when LETTER_GAP =>
                if (gap_done = '1') then
                    next_state <= START_PLAY;
                end if;

            when WORD_GAP =>
                if (gap_done = '1') then
                    next_state <= IDLE;                -- space consumed; fetch next char
                end if;

            when START_PLAY =>
                -- One-cycle state: kick off the Morse Player.
                next_state <= WAIT_PLAY;

            when WAIT_PLAY =>
                if (playback_done = '1') then
                    next_state <= IDLE;
                end if;

            when others =>
                next_state <= IDLE;

        end case;
    end process NextStateLogic;

    -----------------------------------------------------------------------
    -- Controller: Output Logic (Moore - outputs depend only on curr_state)
    -----------------------------------------------------------------------
    OutputLogic : process(curr_state) begin
        char_load     <= '0';
        gap_en        <= '0';
        gap_sel       <= '0';
        need_gap_set  <= '0';
        need_gap_clr  <= '0';
        fifo_read_sig <= '0';
        start_pb_sig  <= '0';

        case (curr_state) is

            when READ_CHAR =>
                fifo_read_sig <= '1';
                char_load     <= '1';

            when LETTER_GAP =>
                gap_en  <= '1';
                gap_sel <= '0';

            when WORD_GAP =>
                gap_en       <= '1';
                gap_sel      <= '1';
                need_gap_clr <= '1';

            when START_PLAY =>
                start_pb_sig <= '1';
                need_gap_set <= '1';

            when others =>
                null;

        end case;
    end process OutputLogic;

    -----------------------------------------------------------------------
    -- Datapath: current_char register
    -- Queue.Data_out is combinational on the head element, so latching here in
    -- the same cycle as fifo_read captures the correct byte before the read
    -- pointer advances.
    -----------------------------------------------------------------------
    char_register : process(clk) begin
        if rising_edge(clk) then
            if char_load = '1' then
                char_reg <= char_in;
            end if;
        end if;
    end process char_register;

    is_space <= '1' when char_reg = SPACE_CHAR else '0';

    -----------------------------------------------------------------------
    -- Datapath: need_gap set/reset flip-flop
    -- Set after a character is started/played; cleared after a word gap.
    -----------------------------------------------------------------------
    need_gap_ff : process(clk) begin
        if rising_edge(clk) then
            if need_gap_clr = '1' then
                need_gap <= '0';
            elsif need_gap_set = '1' then
                need_gap <= '1';
            end if;
        end if;
    end process need_gap_ff;

    -----------------------------------------------------------------------
    -- Datapath: gap timer
    -- Counts t_tick pulses while gap_en is high; target depends on gap_sel.
    -- Cleared whenever gap_en is low so each gap starts from zero.
    -----------------------------------------------------------------------
    gap_timer : process(clk) begin
        if rising_edge(clk) then
            if gap_en = '0' then
                gap_cnt <= (others => '0');
            elsif t_tick = '1' then
                gap_cnt <= gap_cnt + 1;
            end if;
        end if;
    end process gap_timer;

    gap_done <= '1' when (gap_en = '1' and gap_sel = '0' and
                          gap_cnt = LETTER_GAP_UNITS - 1 and t_tick = '1') or
                         (gap_en = '1' and gap_sel = '1' and
                          gap_cnt = WORD_GAP_UNITS - 1 and t_tick = '1')
                    else '0';

    -----------------------------------------------------------------------
    -- Output assignments
    -----------------------------------------------------------------------
    fifo_read      <= fifo_read_sig;
    current_char   <= char_reg;
    start_playback <= start_pb_sig;

end behavioral;
