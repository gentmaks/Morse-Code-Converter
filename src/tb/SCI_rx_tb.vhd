-------------------------------------------------------------------------------
-- SCI_rx_tb.vhd
-- Drives real UART frames (start bit, 8 data bits LSB-first, stop bit) into the
-- SCI receiver and checks rx_data / rx_done_tick. Uses a small Baud_period so
-- the simulation runs quickly.
-------------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;

entity SCI_rx_tb is
end SCI_rx_tb;

architecture testbench of SCI_rx_tb is

    component SCI_rx is
        generic ( Baud_period : integer );
        port (
            clk          : in  STD_LOGIC;
            RsRx         : in  STD_LOGIC;
            rx_shift     : out STD_LOGIC;
            rx_data      : out STD_LOGIC_VECTOR(7 downto 0);
            rx_done_tick : out STD_LOGIC
        );
    end component;

    constant CLK_PERIOD  : time    := 10 ns;   -- 100 MHz
    constant BAUD_PERIOD : integer := 16;      -- clocks per bit (small for fast sim)
    constant BIT_TIME    : time    := BAUD_PERIOD * CLK_PERIOD;

    -- Inputs
    signal clk  : STD_LOGIC := '0';
    signal RsRx : STD_LOGIC := '1';            -- UART idles high

    -- Outputs
    signal rx_shift     : STD_LOGIC;
    signal rx_data      : STD_LOGIC_VECTOR(7 downto 0);
    signal rx_done_tick : STD_LOGIC;

begin

    uut : SCI_rx
        generic map ( Baud_period => BAUD_PERIOD )
        port map (
            clk          => clk,
            RsRx         => RsRx,
            rx_shift     => rx_shift,
            rx_data      => rx_data,
            rx_done_tick => rx_done_tick
        );

    -- Clock
    clk_process : process begin
        clk <= '0';
        wait for CLK_PERIOD/2;
        clk <= '1';
        wait for CLK_PERIOD/2;
    end process clk_process;

    -- Stimulus
    stim_process : process

        -- Send one byte as a standard 8N1 UART frame, LSB first.
        procedure send_byte(constant b : in STD_LOGIC_VECTOR(7 downto 0)) is
        begin
            RsRx <= '0';               -- start bit
            wait for BIT_TIME;
            for i in 0 to 7 loop       -- data bits, LSB first
                RsRx <= b(i);
                wait for BIT_TIME;
            end loop;
            RsRx <= '1';               -- stop bit
            wait for BIT_TIME;
        end procedure;

    begin
        -- Hold idle line for a bit so the receiver settles in IDLE.
        RsRx <= '1';
        wait for 5 * BIT_TIME;

        -- Send 'E' (0x45) and wait for the done pulse, then check the byte.
        -- rx_data latches on the edge leaving DONE, so settle one clock first.
        send_byte(x"45");
        wait until rx_done_tick = '1';
        wait until rising_edge(clk);
        assert rx_data = x"45"
            report "SCI_rx: expected 0x45 ('E'), got something else"
            severity error;

        -- Idle gap between frames.
        wait for 3 * BIT_TIME;

        -- Send 'S' (0x53).
        send_byte(x"53");
        wait until rx_done_tick = '1';
        wait until rising_edge(clk);
        assert rx_data = x"53"
            report "SCI_rx: expected 0x53 ('S'), got something else"
            severity error;

        wait for 3 * BIT_TIME;

        -- Send a space (0x20) to exercise another pattern.
        send_byte(x"20");
        wait until rx_done_tick = '1';
        wait until rising_edge(clk);
        assert rx_data = x"20"
            report "SCI_rx: expected 0x20 (space), got something else"
            severity error;

        wait for 5 * BIT_TIME;
        report "SCI_rx_tb: stimulus complete" severity note;
        wait;
    end process stim_process;

end testbench;
