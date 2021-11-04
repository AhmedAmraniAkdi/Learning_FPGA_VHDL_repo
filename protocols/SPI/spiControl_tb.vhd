library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use std.env.finish;


entity spiControl_tb is
end spiControl_tb;

architecture Behave of spiControl_tb is
    component spiControl is
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
    end component spiControl;
    
    signal i_clk_tb: std_logic := '0'; 
    signal i_reset_tb: std_logic := '0';
    signal i_data_tb: std_logic_vector(7 downto 0) := (others => '0');
    --
    signal i_data_valid_tb: std_logic := '0';
    signal o_data_sent_tb: std_logic; 
    
    -- spi interface
    signal mosi_tb: std_logic; 
    signal sclk_tb: std_logic;
    signal ss_tb: std_logic; 
    constant clk_period : time := 10 ns;
    
begin
    
    uut: spiControl 
    port map(
        i_clk => i_clk_tb,
        i_reset => i_reset_tb,
        i_data => i_data_tb,
        --
        i_data_valid => i_data_valid_tb,
        o_data_sent => o_data_sent_tb,
        
        -- spi interface
        mosi => mosi_tb,
        sclk => sclk_tb,
        ss => ss_tb
    );
    
    clk_process : process
	begin
		wait for clk_period/2;
		i_clk_tb  <= not i_clk_tb ;
	end process clk_process;
    
    test_process: process
    begin
    
        wait for 100ns;
        i_reset_tb <= '1';
        wait for 100ns;
        i_reset_tb <= '0';
        
        i_data_tb <= "10010101";
        wait until i_clk_tb = '1';
        i_data_valid_tb <= '1';
        
        wait until o_data_sent_tb = '1';
        i_data_valid_tb <= '0';
        wait until o_data_sent_tb = '0';
        
        wait for 50ns;
        
        i_data_tb <= "11111110";
        wait until i_clk_tb = '1';
        i_data_valid_tb <= '1';
        
        wait until o_data_sent_tb = '1';
        i_data_valid_tb <= '0';
        wait until o_data_sent_tb = '0';
        
        wait for 300ns;
        finish;
	
    end process test_process;
    
    
    
end Behave;
