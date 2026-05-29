-------------------------------------------------------------------------------
-- SCI_rx.vhd
-- Authors: Gent Maksutaj, Papa Yaw Owusu Nti
-------------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

ENTITY SCI_rx is
    PORT (
        clk: in STD_LOGIC;
        RsRx: in STD_LOGIC;
        rx_shift: out STD_LOGIC;
        rx_data: in STD_LOGIC_VECTOR(7 downto 0);
        rx_done_tick: in STD_LOGIC
    );
end SCI_rx;


ARCHITECTURE behavioral of SCI_rx is

    -- fsm states
    type state_type is (IDLE, START_WAIT, DATA_WAIT, SAMPLE_BIT, DONE, ERR);
    signal curr_state, next_state: state_type := IDLE;

    StateUpdate: process(clk) begin
        if rising_edge(clk) then
            curr_state <= next_state;
        end if;
    end process StateUpdate;

    NextStateLogic: process(clk) begin
    end process NextStateLogic;

    OutputLogic: process(curr_state) begin
        case (curr_state) is
            when IDLE =>
                -- TODO
            when START_WAIT =>
                -- TODO
            when DATA_WAIT =>
                -- TODO
            when SAMPLE_BIT =>
                -- TODO
            when DONE =>
                -- TODO
            when ERR =>
                -- TODO
    end process NextStateLogic;

end behavioral;
