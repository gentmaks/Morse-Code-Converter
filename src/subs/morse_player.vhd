--=============================================================
-- Morse Player
-- Plays one encoded Morse character one T-unit at a time
-- Authors: Gent Maksutaj, Papa Yaw Owusu Nti
--=============================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity morse_player is
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
end morse_player;

architecture Behavioral of morse_player is

    type state_type is (
        IDLE,
        LOAD_CODE,
        OUTPUT_UNIT,
        SHIFT_CODE,
        DONE
    );

    signal current_state, next_state : state_type;

    signal code_reg   : std_logic_vector(18 downto 0) := (others => '0');
    signal length_reg : std_logic_vector(4 downto 0) := (others => '0');

    signal bit_count  : unsigned(4 downto 0) := (others => '0');
    signal unit_count : integer range 0 to UNIT_COUNT - 1 := 0;

    signal code_bit    : std_logic;
    signal bit_done    : std_logic;
    signal length_zero : std_logic;
    signal unit_done   : std_logic;

    signal code_load   : std_logic;
    signal code_shift  : std_logic;
    signal length_load : std_logic;
    signal bit_en      : std_logic;
    signal bit_clr     : std_logic;
    signal unit_en     : std_logic;
    signal unit_clr    : std_logic;

begin

    --=========================================================
    -- Status signals
    --=========================================================

    code_bit <= code_reg(18);

    length_zero <= '1' when unsigned(length_reg) = 0 else '0';

    bit_done <= '1' when unsigned(length_reg) /= 0 and
    bit_count = unsigned(length_reg) - 1
    else '0';

    unit_done <= '1' when unit_count = UNIT_COUNT - 1 else '0';


    --=========================================================
    -- State register
    --=========================================================

    state_update: process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                current_state <= IDLE;
            else
                current_state <= next_state;
            end if;
        end if;
    end process state_update;


    --=========================================================
    -- Next-state and output logic
    --=========================================================

    fsm_logic: process(current_state, start_playback, unit_done,
    bit_done, length_data, code_bit)
    begin
        next_state <= current_state;

        code_load     <= '0';
        code_shift    <= '0';
        length_load   <= '0';
        bit_en        <= '0';
        bit_clr       <= '0';
        unit_en       <= '0';
        unit_clr      <= '0';
        morse_on      <= '0';
        playback_done <= '0';

        case current_state is

            when IDLE =>
                unit_clr <= '1';
                bit_clr  <= '1';

                if start_playback = '1' then
                    next_state <= LOAD_CODE;
                end if;


            when LOAD_CODE =>
                code_load   <= '1';
                length_load <= '1';
                unit_clr    <= '1';
                bit_clr     <= '1';

                if unsigned(length_data) = 0 then
                    next_state <= DONE;
                else
                    next_state <= OUTPUT_UNIT;
                end if;


            when OUTPUT_UNIT =>
                morse_on <= code_bit;
                unit_en  <= '1';

                if unit_done = '1' and bit_done = '0' then
                    next_state <= SHIFT_CODE;

                elsif unit_done = '1' and bit_done = '1' then
                    next_state <= DONE;
                end if;


            when SHIFT_CODE =>
                code_shift <= '1';
                bit_en     <= '1';
                unit_clr   <= '1';

                next_state <= OUTPUT_UNIT;


            when DONE =>
                playback_done <= '1';

                next_state <= IDLE;


            when others =>
                next_state <= IDLE;

        end case;
    end process fsm_logic;


    --=========================================================
    -- Morse code shift register
    --=========================================================

    code_register: process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                code_reg <= (others => '0');

            elsif code_load = '1' then
                code_reg <= morse_data;

            elsif code_shift = '1' then
                code_reg <= code_reg(17 downto 0) & '0';
            end if;
        end if;
    end process code_register;


    --=========================================================
    -- Length register
    --=========================================================

    length_register: process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                length_reg <= (others => '0');

            elsif length_load = '1' then
                length_reg <= length_data;
            end if;
        end if;
    end process length_register;


    --=========================================================
    -- Bit counter
    --=========================================================

    bit_counter: process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                bit_count <= (others => '0');

            elsif bit_clr = '1' then
                bit_count <= (others => '0');

            elsif bit_en = '1' then
                bit_count <= bit_count + 1;
            end if;
        end if;
    end process bit_counter;


    --=========================================================
    -- T-unit timer
    --=========================================================

    unit_timer: process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                unit_count <= 0;

            elsif unit_clr = '1' then
                unit_count <= 0;

            elsif unit_en = '1' then
                if unit_count < UNIT_COUNT - 1 then
                    unit_count <= unit_count + 1;
                end if;
            end if;
        end if;
    end process unit_timer;

end Behavioral;