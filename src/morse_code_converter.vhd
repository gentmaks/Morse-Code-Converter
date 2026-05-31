--------------------------------------------------------------------------------
-- Authors: Gent Maksutaj, Papa Yaw Owusu Nti
-- Course:   Engs 31 25S
-- Final Project (Morse Code Converter)
-- Module Name: morse_code_converter.vhd  (TOP LEVEL)
--------------------------------------------------------------------------------
-- Ties the whole datapath together on the Basys3 (single 100 MHz clock):
--
-- morse_on drives the LED directly and is AND-gated with a 600 Hz square wave
-- (from a second tick_gen) to drive the speaker.
--------------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity morse_code_converter is
    generic (
        -- 9600 baud @ 100 MHz
        BAUD_PERIOD        : integer := 10417;
        -- 1 Morse T-unit (dot) = 100 ms @ 100 MHz  (~12 WPM)
        CLKS_PER_T_UNIT    : integer := 10_000_000;
        -- Half period of a 600 Hz square wave @ 100 MHz: 100e6 / (2*600)
        CLKS_PER_TONE_HALF : integer := 83_333
    );
    port (
        clk_ext_port     : in  STD_LOGIC; -- 100 MHz system clock (W5)
        RsRx_ext_port    : in  STD_LOGIC; -- UART receive line from the AD2 (B18)
        reset_ext_port   : in  STD_LOGIC; -- active-high reset (btnC, U18)
        led_ext_port     : out STD_LOGIC; -- morse_on indicator LED
        speaker_ext_port : out STD_LOGIC  -- gated 600 Hz tone (Pmod pin)
    );
end morse_code_converter;

architecture structural of morse_code_converter is

    --------------------------------------------------------------------------
    -- Component declarations
    --------------------------------------------------------------------------
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

    component Queue is
        port (
            clk      : in  STD_LOGIC;
            Write    : in  STD_LOGIC;
            Read     : in  STD_LOGIC;
            Data_in  : in  STD_LOGIC_VECTOR(7 downto 0);
            Data_out : out STD_LOGIC_VECTOR(7 downto 0);
            Empty    : out STD_LOGIC;
            Full     : out STD_LOGIC
        );
    end component;

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

    component MorseLookup is
        port (
            ascii       : in  STD_LOGIC_VECTOR(7 downto 0);
            morse_data  : out STD_LOGIC_VECTOR(18 downto 0);
            length_data : out STD_LOGIC_VECTOR(4 downto 0)
        );
    end component;

    component morse_player is
        port (
            clk            : in  STD_LOGIC;
            reset          : in  STD_LOGIC;
            start_playback : in  STD_LOGIC;
            unit_tick      : in  STD_LOGIC;
            morse_data     : in  STD_LOGIC_VECTOR(18 downto 0);
            length_data    : in  STD_LOGIC_VECTOR(4 downto 0);
            morse_on       : out STD_LOGIC;
            playback_done  : out STD_LOGIC
        );
    end component;

    component tick_gen is
        generic ( CLKS_PER_TICK : integer );
        port (
            clk  : in  STD_LOGIC;
            en   : in  STD_LOGIC;
            tick : out STD_LOGIC
        );
    end component;

    --------------------------------------------------------------------------
    -- Internal interconnect signals
    --------------------------------------------------------------------------
    signal clk : STD_LOGIC;

    -- SCI_rx -> Queue
    signal rx_data      : STD_LOGIC_VECTOR(7 downto 0);
    signal rx_done_tick : STD_LOGIC;

    -- Queue <-> Scheduler
    signal q_data_out : STD_LOGIC_VECTOR(7 downto 0);
    signal q_empty    : STD_LOGIC;
    signal q_full     : STD_LOGIC;
    signal fifo_read  : STD_LOGIC;

    -- Scheduler <-> encoder / player
    signal current_char   : STD_LOGIC_VECTOR(7 downto 0);
    signal start_playback : STD_LOGIC;
    signal playback_done  : STD_LOGIC;

    -- Encoder -> player
    signal morse_data  : STD_LOGIC_VECTOR(18 downto 0);
    signal length_data : STD_LOGIC_VECTOR(4 downto 0);

    -- Timing ticks
    signal t_unit_tick : STD_LOGIC;
    signal tone_tick   : STD_LOGIC;

    -- Output gating
    signal morse_on  : STD_LOGIC;
    signal tone_wave : STD_LOGIC := '0';

begin

    clk <= clk_ext_port;

    --------------------------------------------------------------------------
    -- UART receiver: serial line -> parallel byte + done pulse
    --------------------------------------------------------------------------
    rx : SCI_rx
        generic map ( Baud_period => BAUD_PERIOD )
        port map (
            clk          => clk,
            RsRx         => RsRx_ext_port,
            rx_shift     => open,
            rx_data      => rx_data,
            rx_done_tick => rx_done_tick
        );

    --------------------------------------------------------------------------
    -- Message FIFO: buffers received bytes for playback
    --------------------------------------------------------------------------
    fifo : Queue
        port map (
            clk      => clk,
            Write    => rx_done_tick,
            Read     => fifo_read,
            Data_in  => rx_data,
            Data_out => q_data_out,
            Empty    => q_empty,
            Full     => q_full
        );

    --------------------------------------------------------------------------
    -- Playback scheduler: gaps + start/stop control
    --------------------------------------------------------------------------
    sched : Scheduler
        port map (
            clk            => clk,
            t_tick         => t_unit_tick,
            fifo_empty     => q_empty,
            char_in        => q_data_out,
            playback_done  => playback_done,
            fifo_read      => fifo_read,
            current_char   => current_char,
            start_playback => start_playback
        );

    --------------------------------------------------------------------------
    -- Character encoder ROM: ASCII -> 19-bit Morse waveform + length
    --------------------------------------------------------------------------
    encoder : MorseLookup
        port map (
            ascii       => current_char,
            morse_data  => morse_data,
            length_data => length_data
        );

    --------------------------------------------------------------------------
    -- Morse player: streams the waveform one T-unit at a time
    --------------------------------------------------------------------------
    player : morse_player
        port map (
            clk            => clk,
            reset          => reset_ext_port,
            start_playback => start_playback,
            unit_tick      => t_unit_tick,
            morse_data     => morse_data,
            length_data    => length_data,
            morse_on       => morse_on,
            playback_done  => playback_done
        );

    --------------------------------------------------------------------------
    -- T-unit timebase: shared by the scheduler gap timer and the player
    --------------------------------------------------------------------------
    t_unit_gen : tick_gen
        generic map ( CLKS_PER_TICK => CLKS_PER_T_UNIT )
        port map (
            clk  => clk,
            en   => '1',
            tick => t_unit_tick
        );

    --------------------------------------------------------------------------
    -- Tone timebase: tick at twice 600 Hz, toggle to make a 600 Hz square wave
    --------------------------------------------------------------------------
    tone_gen : tick_gen
        generic map ( CLKS_PER_TICK => CLKS_PER_TONE_HALF )
        port map (
            clk  => clk,
            en   => '1',
            tick => tone_tick
        );

    tone_toggle : process(clk) begin
        if rising_edge(clk) then
            if tone_tick = '1' then
                tone_wave <= not tone_wave;
            end if;
        end if;
    end process tone_toggle;

    --------------------------------------------------------------------------
    -- Output driver: LED follows morse_on; speaker is the gated tone
    --------------------------------------------------------------------------
    led_ext_port     <= morse_on;
    speaker_ext_port <= morse_on and tone_wave;

end structural;
