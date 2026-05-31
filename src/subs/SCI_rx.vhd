--------------------------------------------------------------------------------
-- SCI_rx.vhd
-- Authors: Gent Maksutaj, Papa Yaw Owusu Nti
--------------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity SCI_rx is
    generic (
        Baud_period : integer := 10417
    );
    port (
        clk          : in  STD_LOGIC;
        RsRx         : in  STD_LOGIC;
        rx_shift     : out STD_LOGIC;
        rx_data      : out STD_LOGIC_VECTOR(7 downto 0);
        rx_done_tick : out STD_LOGIC
    );
end SCI_rx;

architecture behavioral of SCI_rx is

    type state_type is (
        IDLE,
        START_WAIT,
        DATA_WAIT,
        STOP_WAIT,
        DONE,
        ERR
    );

    signal curr_state, next_state : state_type := IDLE;

    -- Double flip-flop synchronizer
    signal Rx_sync_tmp, Rx_sync_done : STD_LOGIC := '1';

    -- Terminal count signals
    signal half_tc : STD_LOGIC := '0';
    signal baud_tc : STD_LOGIC := '0';
    signal bit_tc  : STD_LOGIC := '0';

    -- Datapath control signals
    signal baud_clr    : STD_LOGIC := '0';
    signal baud_en     : STD_LOGIC := '0';
    signal half_sel    : STD_LOGIC := '0';
    signal bit_clr     : STD_LOGIC := '0';
    signal bit_en      : STD_LOGIC := '0';
    signal shift_en    : STD_LOGIC := '0';
    signal data_load   : STD_LOGIC := '0';
    signal frame_error : STD_LOGIC := '0';

    -- Datapath registers
    signal shift_reg : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
    signal data_reg  : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');

    -- Counters
    signal baud_cnt : unsigned(13 downto 0) := (others => '0');
    signal bit_cnt  : unsigned(3 downto 0)  := (others => '0');

    constant DATA_BITS : integer := 8;

begin

    -----------------------------------------------------------------------
    -- Double Flip-Flop Synchronizer
    -----------------------------------------------------------------------
    Sync : process(clk)
    begin
        if rising_edge(clk) then
            Rx_sync_tmp  <= RsRx;
            Rx_sync_done <= Rx_sync_tmp;
        end if;
    end process Sync;

    -----------------------------------------------------------------------
    -- Controller: State Update
    -----------------------------------------------------------------------
    StateUpdate : process(clk)
    begin
        if rising_edge(clk) then
            curr_state <= next_state;
        end if;
    end process StateUpdate;

    -----------------------------------------------------------------------
    -- Controller: Next State Logic
    -----------------------------------------------------------------------
    NextStateLogic : process(curr_state, Rx_sync_done, half_tc, baud_tc, bit_tc)
    begin
        next_state <= curr_state;

        case curr_state is

            when IDLE =>
                if Rx_sync_done = '0' then
                    next_state <= START_WAIT;
                end if;

            when START_WAIT =>
                if half_tc = '1' then
                    if Rx_sync_done = '0' then
                        next_state <= DATA_WAIT;
                    else
                        next_state <= IDLE;
                    end if;
                end if;

            when DATA_WAIT =>
                if baud_tc = '1' then
                    if bit_tc = '1' then
                        next_state <= STOP_WAIT;
                    else
                        next_state <= DATA_WAIT;
                    end if;
                end if;

            when STOP_WAIT =>
                if baud_tc = '1' then
                    if Rx_sync_done = '1' then
                        next_state <= DONE;
                    else
                        next_state <= ERR;
                    end if;
                end if;

            when DONE =>
                next_state <= IDLE;

            when ERR =>
                next_state <= IDLE;

            when others =>
                next_state <= IDLE;

        end case;
    end process NextStateLogic;

    -----------------------------------------------------------------------
    -- Controller: Output Logic
    -----------------------------------------------------------------------
    OutputLogic : process(curr_state, baud_tc, Rx_sync_done)
    begin
        baud_clr     <= '0';
        baud_en      <= '0';
        half_sel     <= '0';
        bit_clr      <= '0';
        bit_en       <= '0';
        shift_en     <= '0';
        data_load    <= '0';
        rx_done_tick <= '0';
        frame_error  <= '0';

        case curr_state is

            when IDLE =>
                baud_clr <= '1';
                bit_clr  <= '1';

            when START_WAIT =>
                baud_en  <= '1';
                half_sel <= '1';

            when DATA_WAIT =>
                baud_en <= '1';

                -- Sample the data bit on the baud terminal-count clock.
                -- This avoids the one-clock-late SAMPLE_BIT state.
                if baud_tc = '1' then
                    shift_en  <= '1';
                    bit_en    <= '1';
                    baud_clr  <= '1';
                end if;

            when STOP_WAIT =>
                baud_en <= '1';

                -- If the stop bit is valid, latch the completed byte
                -- on the same clock edge that moves into DONE.
                if baud_tc = '1' and Rx_sync_done = '1' then
                    data_load <= '1';
                end if;

            when DONE =>
                rx_done_tick <= '1';

            when ERR =>
                frame_error <= '1';
                bit_clr     <= '1';

            when others =>
                null;

        end case;
    end process OutputLogic;

    -----------------------------------------------------------------------
    -- Datapath: Baud Counter
    -----------------------------------------------------------------------
    baud_counter : process(clk)
    begin
        if rising_edge(clk) then
            if baud_clr = '1' then
                baud_cnt <= (others => '0');

            elsif baud_en = '1' then
                if (half_sel = '1' and baud_cnt = Baud_period/2 - 1) or
                (half_sel = '0' and baud_cnt = Baud_period - 1) then
                    baud_cnt <= (others => '0');
                else
                    baud_cnt <= baud_cnt + 1;
                end if;
            end if;
        end if;
    end process baud_counter;

    half_tc <= '1' when
    baud_en = '1' and half_sel = '1' and
    baud_cnt = Baud_period/2 - 1
    else '0';

    baud_tc <= '1' when
    baud_en = '1' and half_sel = '0' and
    baud_cnt = Baud_period - 1
    else '0';

    -----------------------------------------------------------------------
    -- Datapath: Bit Counter
    -----------------------------------------------------------------------
    bit_counter : process(clk)
    begin
        if rising_edge(clk) then
            if bit_clr = '1' then
                bit_cnt <= (others => '0');

            elsif bit_en = '1' then
                bit_cnt <= bit_cnt + 1;
            end if;
        end if;
    end process bit_counter;

    -- This is true before sampling the 8th data bit.
    -- bit_cnt values before each data sample are 0,1,2,3,4,5,6,7.
    bit_tc <= '1' when bit_cnt = DATA_BITS - 1 else '0';

    -----------------------------------------------------------------------
    -- Datapath: Shift Register
    -----------------------------------------------------------------------
    shift_register : process(clk)
    begin
        if rising_edge(clk) then
            if shift_en = '1' then
                shift_reg <= Rx_sync_done & shift_reg(7 downto 1);
            end if;

            if data_load = '1' then
                data_reg <= shift_reg;
            end if;
        end if;
    end process shift_register;

    -----------------------------------------------------------------------
    -- Output Assignments
    -----------------------------------------------------------------------
    rx_data  <= data_reg;
    rx_shift <= shift_en;

end behavioral;