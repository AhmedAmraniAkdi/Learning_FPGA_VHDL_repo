library ieee;library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- takes the pixel data from the img
-- puts it on the linebuffers
-- and sends it to the conv module

entity imageControl is
    generic (
        g_width       : natural := 8;
        n_elems       : natural := 9
    );
    port (
        i_clk         : in std_logic;
        i_rst         : in std_logic;
        --
        i_pixel_valid : in std_logic; -- data ready on input
        i_pixel_data  : in std_logic_vector(g_width - 1 downto 0); -- input
        --
        o_data        : out std_logic_vector(g_width * n_elems - 1 downto 0);
        o_data_valid  : out std_logic;
        o_intr        : out std_logic

    );
end imageControl;


architecture rtl of imageControl is
    -- internal signals
    -- writing
    signal pixel_counter_write: natural range 0 to 511;
    signal current_write_buffer: natural range 0 to 3;
    signal linebuffer_data_valid: std_logic_vector(3 downto 0);
    -- reading
    signal pixel_counter_read: natural range 0 to 511;
    signal current_read_buffer: natural range 0 to 3;
    signal linebuffer_read_data_valid: std_logic_vector(3 downto 0);
    signal linebuffers_data: std_logic_vector(24 * 4 - 1 downto 0); -- 3  bytes from each linebuffer
   
    signal can_read: std_logic;
    -- state machine can only read if 3 buffers are full
    signal total_pixels: natural range 0 to 2048 - 1;
    
    type t_fsm_state is (IDLE, RD_BUFFER);
    signal curr_state: t_fsm_state;

begin

    -- STATE MACHINE: can only read from output if 3 buffers are full, so 512 * 3 = 1536 11 bits
    -- all constants can become generic later
    
    o_data_valid <= can_read;
    
    count_allbuffers_pixels : process(i_clk) is   
    begin
        if rising_edge(i_clk) then
            if(i_rst) then
                total_pixels <= 0;
            else
                if(i_pixel_valid and not can_read) then
                    total_pixels <= total_pixels + 1;
                else if (not i_pixel_valid and can_read) then
                    total_pixels <= total_pixels - 1;
                    end if;
                end if;
            end if;
        end if;
    end process count_allbuffers_pixels;
    
    fsm : process(i_clk) is   
    begin
        if rising_edge(i_clk) then
            if(i_rst) then
                curr_state <= IDLE;
                can_read <= '0';
                o_intr <= '0';
            else
                case curr_state is
                when IDLE =>
                    o_intr <= '0';
                    if(total_pixels >= 1536) then
                        can_read <= '1';
                        curr_state <= RD_BUFFER;
                    end if;
                when RD_BUFFER =>
                    if(pixel_counter_read = 511) then
                        curr_state <= IDLE;
                        can_read <= '0';
                        o_intr <= '1';
                    end if;
                end case;
            end if;
        end if;
    end process fsm;
    

    -- LEFT PART: controlling to which linebuffer/pixel we write
    
    wcount_px : process(i_clk) is   
    begin
        if rising_edge(i_clk) then
            if(i_rst) then
                pixel_counter_write <= 0;
            else
                if(i_pixel_valid) then -- natural up to 511, so 9 bits exactly, no need for an if else for wrapping?
                    pixel_counter_write <= pixel_counter_write + 1;
                end if;
            end if;
        end if;
    end process wcount_px;

    to_which_buffer : process(i_clk) is   
    begin
        if rising_edge(i_clk) then
            if(i_rst) then
                current_write_buffer <= 0;
            else
                if(pixel_counter_write = 511 and i_pixel_valid = '1') then --already have the 511 and received the 512
                    current_write_buffer <= current_write_buffer + 1; -- same case, 4 bits natural no need for wrapping?
                end if;
            end if;
        end if;
    end process to_which_buffer;
    
    currentWbuffer_datavalid: process(all) is
    begin
        case current_write_buffer is -- decoder, easier to read than boolean eq
            when 0 => 
                linebuffer_data_valid <= "0001";
            when 1 =>
                linebuffer_data_valid <= "0010";
            when 2 =>
                linebuffer_data_valid <= "0100";
            when 3 =>
                linebuffer_data_valid <= "1000";
        end case;
    end process currentWbuffer_datavalid;
    
    -- RIGHT part: controlling from which linebuffer/pixel we read
    
    rcount_px : process(i_clk) is   
    begin
        if rising_edge(i_clk) then
            if(i_rst) then
                pixel_counter_read <= 0;
            else
                if(can_read) then -- natural up to 511, so 9 bits exactly, no need for an if else for wrapping?
                    pixel_counter_read <= pixel_counter_read + 1;
                end if;
            end if;
        end if;
    end process rcount_px;
    
    from_which_buffers : process(i_clk) is   
    begin
        if rising_edge(i_clk) then
            if(i_rst) then
                current_read_buffer <= 0;
            else
                if(pixel_counter_read = 511 and can_read = '1') then --already have the 511 and received the 512
                    current_write_buffer <= current_write_buffer + 1; -- same case, 4 bits natural no need for wrapping?
                end if;
            end if;
        end if;
    end process from_which_buffers;
    
    currentRbuffer_datavalid: process(all) is
    begin
        case current_write_buffer is
            when 0 => 
                linebuffer_read_data_valid <= "0111";
            when 1 =>
                linebuffer_read_data_valid <= "1110";
            when 2 =>
                linebuffer_read_data_valid <= "1101";
            when 3 =>
                linebuffer_read_data_valid <= "1011";
        end case;
    end process currentRbuffer_datavalid;
    
    out_data: process(all) is
    begin
        case current_write_buffer is
            when 0 => 
                o_data <= linebuffers_data(24 * 3 - 1 downto 0);
            when 1 =>
                o_data <= linebuffers_data(24 * 4 - 1 downto 24);
            when 2 =>
                o_data <= linebuffers_data(24 * 4 - 1 downto 48) & linebuffers_data(24 * 1 - 1 downto 0);
            when 3 =>
                o_data <= linebuffers_data(24 * 4 - 1 downto 72) & linebuffers_data(48 - 1 downto 0);
        end case;
    end process out_data;
    
        -- 4 lines, 3 for the current processed lines and 1 as a buffer
    inst_linebuffers: for i in 0 to 3 generate
        entity_linebuffer: entity work.linebuffer
            port map(
                i_clk => i_clk,
                i_rst => i_rst,
                --
                i_data_valid => linebuffer_data_valid(i), -- data ready on input
                i_data => i_pixel_data, -- input
                i_read_data => linebuffer_read_data_valid(i), -- data read signal (when reading output)
                --
                o_data => linebuffers_data((i + 1) * 24 - 1 downto i * 24)
            );
    end generate;

end rtl;