
-- Exercice on communication protocols for embedded systems
-- Implementation of SPI protocol (3-wires spimode 00, no need for the fpga to read data 
-- from the display) for an OLED DISPLAY on vhdl
-- ref: https://www.youtube.com/watch?v=V8jW81VaLOg
--      https://www.youtube.com/watch?v=MCi7dCBhVpQ

-- the way I understood it is that the fabricant gives you the component datasheet with it comm protocol
-- and we have to implement the comm interface while respecting the chronogram
-- https://cdn-shop.adafruit.com/datasheets/UG-2864HSWEG01.pdf

-- chip select always low, only 1 spi peripheral
-- if we wanted to use chip select, we can use a state machine, because there are some timing constraints 
-- (from datasheet 30ns = setup and hold time of chip select before we can start sending data), and we can 
-- for example say, if after 3 clock cycles i_data_valid is not high, then we go back to disabled 
-- state(chip select high)

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity spiControl is
    port (
    i_clk: in std_logic; -- 100 Mhz
    i_reset: in std_logic;
    i_data: in std_logic_vector(7 downto 0);
    --
    i_data_valid: in std_logic; -- data available at input to be sent through spi 
    o_data_sent: out std_logic; -- done sending data through spi, put data at input to be sent
    
    -- spi interface
    mosi: out std_logic; 
    sclk: out std_logic; -- 10MHz clock (datasheet)
    ss: out std_logic -- always low in our case, only 1 slave - the oled display
    );
end spiControl;

architecture Behavioral of spiControl is
    
    -- in order to divide the frequency of i_clk, we need a counter to 10
    -- from which the first half sclk will be high, and the second half sclk low
    -- it's a frequency divider
    signal r_counter: unsigned(2 downto 0) := (others => '0');
    signal r_sclk : std_logic := '0';
    signal r_ce: std_logic := '0'; -- spi clock enable
    
    -- storing the in data
    signal r_shift_reg: std_logic_vector(7 downto 0) := (others => '0');
    
    -- to count the bits sent through the mosi pin 
    signal r_sending_counter: unsigned(2 downto 0) := (others => '0');
    
    -- fsm for controlling communication protoocl
    type t_fsm_state is (IDLE, SENDING, DONE);
    signal curr_state : t_fsm_state := IDLE;
        
begin
    
    p_counter: process (i_clk) is
    begin
        if rising_edge(i_clk) then
            if (r_counter /= 4) then
                r_counter <= r_counter + 1;
            else
                r_counter <= 3b"0";
            end if;
        end if;
    end process p_counter;
    
    ss <= '0';
    sclk <= r_sclk when (r_ce = '1') else '1';
    
    p_sclk: process (i_clk) is
    begin
        if rising_edge(i_clk) then
            if (r_counter = 4) then
                r_sclk <= not r_sclk;
            end if;
        end if;
    end process p_sclk;
    
    -- fsm for communication part
    
    p_fsm_comms: process (r_sclk) is
    begin
        if falling_edge(r_sclk) then
            if(i_reset = '1') then
                curr_state <= IDLE;
                r_sending_counter <= (others => '0');
                o_data_sent <= '0';
                mosi <= '0';
                r_ce <= '0';
            else 
                case curr_state is
                when IDLE =>
                    if(i_data_valid = '1') then
                        r_shift_reg <= i_data;
                        r_sending_counter <= (others => '0');
                        curr_state <= SENDING;
                    end if;
                when SENDING =>
                    mosi <= r_shift_reg(7);
                    r_shift_reg <= (r_shift_reg(6 downto 0), r_shift_reg(7));
                    r_ce <= '1';
                    if (r_sending_counter /= 7) then
                        r_sending_counter <= r_sending_counter + 1;
                    else
                        r_sending_counter <= (others => '0');
                        curr_state <= DONE; -- sent all the byte
                    end if;
                when DONE =>
                    r_ce <= '0';
                    o_data_sent <= '1';
                    if(i_data_valid = '0') then   -- we receive data sent high, we put data valid low as a handshake
                        o_data_sent <= '0';       -- we go back to idle
                        curr_state <= IDLE;
                    end if;
                when others => null;
                end case;
            end if;
        end if;
    end process p_fsm_comms;
    
    
    
    
   

end Behavioral;
