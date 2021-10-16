library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity conv is
    generic (
        g_width: natural := 8;
        kernelradius: natural := 1;
        n_elems : natural := 9
    );
    port (
        i_clk : in std_logic;
        --
        i_pixel_valid: in std_logic; -- data ready on input
        i_pixel_data: in std_logic_vector(n_elems * g_width - 1 downto 0); -- input
        --
        o_data: out std_logic_vector(g_width - 1 downto 0);
        o_data_valid: out std_logic

    );
end conv;


architecture rtl of conv is
    -- internal signals
    type t_kernel is array (0 to n_elems - 1) of integer range -2**g_width to (2**g_width) - 1;
    signal r_kernel : t_kernel := (others => 1);
    --
    type t_mult_data is array (0 to n_elems - 1) of integer range -2**(g_width + 1) to (2**(g_width + 1)) - 1;
    signal r_mult_data : t_mult_data := (others => 0);
    --
    signal r_acum : integer range -2**(g_width + 1) to (2**(g_width + 1)) - 1;
    --
    signal pipeline_mult : std_logic;
    signal pipeline_acum: std_logic;


begin

    p_mult : process(i_clk) is   
    begin
        if rising_edge(i_clk) then
            for i in 0 to n_elems - 1 loop
                r_mult_data(i) <= r_kernel(i) * to_integer( signed(i_pixel_data((i + 1) * g_width - 1 to g_width * i)) );
            end loop;
            pipeline_mult <= i_pixel_valid;
        end if;
    end process p_mult;
    
    -- by how signals work, an iterative sum would not work, need variables
    -- does it even need to be a process?
    p_acum : process(r_mult_data, pipeline_mult) is 
    variable v_acum : integer range -2**(g_width + 1) to (2**(g_width + 1)) - 1; 
    begin
        v_acum := 0;
        for i in 0 to n_elems - 1 loop
            v_acum := v_acum + r_mult_data(i);
        end loop;
        r_acum <= v_acum;
        pipeline_acum <= pipeline_mult;
    end process p_acum;
    
    p_out : process(r_acum, pipeline_acum) is   
    begin
        o_data <= std_logic_vector(to_signed(r_acum / 9, g_width));
        o_data_valid <= pipeline_acum;
    end process p_out;
    
end rtl;
