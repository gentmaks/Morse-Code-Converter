--------------------------------------------------------------------------------
-- SCI_rx.vhd
-- Authors: Gent Maksutaj, Papa Yaw Owusu Nti
--------------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

ENTITY SCI_rx is
    generic (
        Baud_period : integer := 10417
    );
    PORT (
        clk          : in  STD_LOGIC;
        RsRx         : in  STD_LOGIC;
        rx_shift     : out STD_LOGIC;                    -- high while a bit is being shifted in
        rx_data      : out STD_LOGIC_VECTOR(7 downto 0); -- received byte
        rx_done_tick : out STD_LOGIC                     -- 1-cycle pulse when byte is ready
    );
end SCI_rx;

ARCHITECTURE behavioral of SCI_rx is

    -- FSM states
    type state_type is (
        IDLE,
        START_WAIT,
        DATA_WAIT,
        SAMPLE_BIT,
        STOP_WAIT,
        DONE,
        ERR
    );

    signal curr_state, next_state : state_type := IDLE;

    -- Double flip-flop synchronizer outputs
    signal Rx_sync_tmp, Rx_sync_done : STD_LOGIC := '1'; -- init to '1' (idle line)

    -- FSM input signals (terminal counts)
    signal half_tc : STD_LOGIC := '0'; -- baud counter reached half period
    signal baud_tc : STD_LOGIC := '0'; -- baud counter reached full period
    signal bit_tc  : STD_LOGIC := '0'; -- bit counter reached 8 (all data bits received)

    -- FSM output signals (datapath control)
    signal baud_clr   : STD_LOGIC := '0'; -- reset baud counter
    signal baud_en    : STD_LOGIC := '0'; -- enable baud counter to count
    signal half_sel   : STD_LOGIC := '0'; -- '1' = count to half period; '0' = full period
    signal bit_clr    : STD_LOGIC := '0'; -- reset bit counter
    signal bit_en     : STD_LOGIC := '0'; -- increment bit counter
    signal shift_en   : STD_LOGIC := '0'; -- shift RsRx into shift register
    signal data_load  : STD_LOGIC := '0'; -- latch shift register into data register
    signal frame_error: STD_LOGIC := '0'; -- stop bit was wrong (framing error)

    -- Datapath registers
    signal shift_reg  : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
    signal data_reg   : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');

    -- Counters
    signal baud_cnt : unsigned(13 downto 0) := (others => '0'); -- up to 10417
    signal bit_cnt  : unsigned(3 downto 0)  := (others => '0'); -- up to 8

    constant DATA_BITS : integer := 8;

begin

    -----------------------------------------------------------------------
    -- Double Flip-Flop Synchronizer (prevents metastability)
    -----------------------------------------------------------------------
    Sync : process(clk) begin
        if rising_edge(clk) then
            Rx_sync_tmp  <= RsRx;
            Rx_sync_done <= Rx_sync_tmp;
        end if;
    end process Sync;

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
    NextStateLogic : process(curr_state, Rx_sync_done, half_tc, baud_tc, bit_tc) begin
        next_state <= curr_state;

        case (curr_state) is

            when IDLE =>
                -- Idle line is '1'. A '0' means a start bit has arrived.
                if (Rx_sync_done = '0') then
                    next_state <= START_WAIT;
                end if;

            when START_WAIT =>
                -- Waiting until we are at the CENTER of the start bit (half period).
                if (half_tc = '1' and Rx_sync_done = '0') then
                    next_state <= DATA_WAIT;
                elsif (half_tc = '1' and Rx_sync_done = '1') then
                    next_state <= IDLE;
                end if;

            when DATA_WAIT =>
                -- Wait one full baud period, then sample the data bit.
                if (baud_tc = '1') then
                    next_state <= SAMPLE_BIT;
                end if;

            when SAMPLE_BIT =>
                -- We just sampled one bit. If all 8 data bits are done, go
                -- wait for the stop bit. Otherwise go wait for the next bit.
                if (bit_tc = '1') then
                    next_state <= STOP_WAIT;
                else
                    next_state <= DATA_WAIT;
                end if;

            when STOP_WAIT =>
                -- Wait one full baud period, then check the stop bit.
                -- Stop bit MUST be '1'. If not, it's a framing error.
                if (baud_tc = '1' and Rx_sync_done = '1') then
                    next_state <= DONE;
                elsif (baud_tc = '1' and Rx_sync_done = '0') then
                    next_state <= ERR;
                end if;

            when DONE =>
                -- One-cycle state: pulse rx_done_tick, load data, return to IDLE.
                next_state <= IDLE;

            when ERR =>
                -- One-cycle state: pulse frame_error, return to IDLE.
                next_state <= IDLE;

            when others =>
                next_state <= IDLE;

        end case;
    end process NextStateLogic;

    -----------------------------------------------------------------------
    -- Controller: Output Logic (Moore — outputs depend only on curr_state)
    -----------------------------------------------------------------------
    OutputLogic : process(curr_state) begin
        baud_clr    <= '0';
        baud_en     <= '0';
        half_sel    <= '0';
        bit_clr     <= '0';
        bit_en      <= '0';
        shift_en    <= '0';
        data_load   <= '0';
        rx_done_tick<= '0';
        frame_error <= '0';

        case (curr_state) is

            when IDLE =>
                baud_clr <= '1';
                bit_clr  <= '1';

            when START_WAIT =>
                baud_en  <= '1';
                half_sel <= '1';

            when DATA_WAIT =>
                baud_en  <= '1';

            when SAMPLE_BIT =>
                shift_en <= '1';
                bit_en   <= '1';
                baud_clr <= '1';

            when STOP_WAIT =>
                baud_en  <= '1';

            when DONE =>
                rx_done_tick <= '1';
                data_load    <= '1';

            when ERR =>
                frame_error  <= '1';
                bit_clr      <= '1';

            when others =>
                null;

        end case;
    end process OutputLogic;

    -----------------------------------------------------------------------
    -- Datapath: Baud Counter
    -- Counts clock cycles to measure one bit period (or half a period).
    -- half_sel = '1'  → terminal count at BAUD_PERIOD/2
    -- half_sel = '0'  → terminal count at BAUD_PERIOD-1
    -----------------------------------------------------------------------
    baud_counter : process(clk) begin
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

    half_tc <= '1' when (baud_en = '1' and half_sel = '1' and
                         baud_cnt = Baud_period/2 - 1) else '0';
    baud_tc <= '1' when (baud_en = '1' and half_sel = '0' and
                         baud_cnt = Baud_period - 1)   else '0';

    -----------------------------------------------------------------------
    -- Datapath: Bit Counter
    -- bit_tc fires when the 8th (last) data bit is being sampled.
    -----------------------------------------------------------------------
    bit_counter : process(clk) begin
        if rising_edge(clk) then
            if bit_clr = '1' then
                bit_cnt <= (others => '0');
            elsif bit_en = '1' then
                bit_cnt <= bit_cnt + 1;
            end if;
        end if;
    end process bit_counter;

    bit_tc <= '1' when (bit_en = '1' and bit_cnt = DATA_BITS - 1) else '0';

    -----------------------------------------------------------------------
    -- Datapath: Shift Register
    -- Shifts in LSB-first (standard UART bit order).
    -- On shift_en: incoming bit enters at MSB, everything shifts right.
    -- After 8 shifts: shift_reg holds [D7 D6 D5 D4 D3 D2 D1 D0].
    -----------------------------------------------------------------------
    shift_register : process(clk) begin
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
    -- Output assignments
    -----------------------------------------------------------------------
    rx_data  <= data_reg;
    rx_shift <= shift_en;

end behavioral;
