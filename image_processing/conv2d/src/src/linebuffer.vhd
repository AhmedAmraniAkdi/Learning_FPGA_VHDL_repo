-- Simple fifo whose write and read pointers warp around
-- the output is 3 bytes for a convolution
-- for the borders the convolution line warps around better than padding with zeros and adding more memory


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity linebuffer is
    generic (
        g_width: natural := 8;
        kernelradius: natural := 1;
        g_depth: natural := 512
    );
    port (
        i_clk : in std_logic;
        i_rst: in std_logic;
        --
        i_data_valid: in std_logic; -- data ready on input
        i_data: in std_logic_vector(g_width - 1 downto 0); -- input
        i_read_data: in std_logic; -- data read signal (when reading output)
        --
        o_data: out std_logic_vector((kernelradius * 2 + 1) * g_width - 1 downto 0)

    );
end linebuffer;


architecture rtl of linebuffer is
    -- internal signals
    type t_buf_data is array (g_depth - 1 downto 0) of std_logic_vector(g_width - 1 downto 0);
    signal r_buf_data : t_buf_data := (others => (others => '0'));
    signal r_write_ptr : unsigned(8 downto 0) := (others => '0'); --natural range 0 to g_depth -1 := 0;
    signal r_read_ptr : unsigned(8 downto 0) := (others => '0'); --natural range 0 to g_depth -1 := 0;

begin

    p_writing_data : process(i_clk) is   
    begin
        if rising_edge(i_clk) then
            if(i_data_valid = '1') then
                r_buf_data(to_integer(r_write_ptr)) <= i_data;
            end if;
        end if;
    end process p_writing_data;
    
    p_write_ptr_control : process(i_clk) is   
    begin
        if rising_edge(i_clk) then
            if(i_rst = '1') then
                r_write_ptr <= (others => '0');
            elsif(i_data_valid = '1') then
                r_write_ptr <= r_write_ptr + 1;
            end if;
        end if;
    end process p_write_ptr_control;
    
    -- wrap around better than having double the depth for the padding
    -- https://stackoverflow.com/questions/13446580/is-integer-overflow-defined-in-vhdl
    o_data <= r_buf_data(to_integer(r_read_ptr - 1)) & r_buf_data(to_integer(r_read_ptr)) & r_buf_data(to_integer(r_read_ptr + 1));

    p_read_ptr_control : process(i_clk) is   
    begin
        if rising_edge(i_clk) then
            if(i_rst = '1') then
                r_read_ptr <= (others => '0');
            elsif(i_read_data = '1') then
                r_read_ptr <= r_read_ptr + 1;
            end if;
        end if;
    end process p_read_ptr_control;
    
end rtl;