library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- http://zipcpu.com/dsp/2017/07/21/bit-growth.html
-- http://zipcpu.com/dsp/2017/07/22/rounding.html
-- http://zipcpu.com/dsp/2017/09/15/fastfir.html
-- https://www.xilinx.com/publications/archives/xcell/Xcell80.pdf (page 45)
-- https://www.youtube.com/watch?v=_1LlX-V5yCA

-- let's say the input signal goes from -5V to 5 V
-- and that the output has to be accurate to +/-0.001V
-- the filter is a LPF with cutoff freq 1KHz
-- sampling frequency of 44100Hz
-- for later: the fpga running at 100MHz but the Fs is 44,1KHz

-- input/output already comes in/goes signed, scalling is done outside fpga 

-- We will use 16 bits inputs and outputs 
--(input size will be determined by accuracy too, just that there is no specificiation for this problem)
-- -5 to 5 means 4 bits for integer part, leaves us with 12 bits for fractional part so 4,12 format
-- the filter coefficients are all fractional -> so 1,15 format (1 for sign)

-- multiply registers will be 4,27 = 1+3+0,12+15 so 31 bits total
-- accum registers will be 31+4 = 31 + ceil_log2(10)

-- at the end we will truncate the fractional part to fit in the output register
-- rounding is better, for later, after testbench

entity pipelined_transposed_fir is
    generic (
        in_width   : natural := 16;
        coeff_width: natural := 16;
        out_width  : natural := 16;
        num_taps   : natural := 10;
        
        multiply_width: natural := 31;
        accum_width   : natural := 35   
    );
    port ( 
        -- in
        i_clk    : in std_logic;
        i_reset  : in std_logic;
        x        : in std_logic_vector(in_width - 1 downto 0);
        in_valid : in std_logic;
        -- out
        y        : out std_logic_vector(out_width -1 downto 0);
        out_valid: out std_logic
    );
end pipelined_transposed_fir;

architecture rtl of pipelined_transposed_fir is
    
    -- right at input
    type t_in_reg is array (0 to num_taps - 1) of signed(in_width - 1 downto 0);
    signal r_a_pipe : t_in_reg := (others => (others => '0'));
    signal r_a_valid : std_logic := '0';
    
    -- after coefficient multiplication
    type t_mult_reg is array (0 to num_taps - 1) of signed(multiply_width - 1 downto 0);
    signal r_mult_reg : t_mult_reg := (others => (others => '0'));
    signal r_mult_valid : std_logic := '0';
    
    -- for accum
    type t_accum_reg is array (0 to num_taps - 1) of signed(accum_width - 1 downto 0);
    signal r_accum_reg : t_accum_reg := (others => (others => '0'));
    -- signal r_accum_valid : std_logic := '0'; it's the output
    
    -- coefficients
    type t_coeff_reg is array (0 to num_taps - 1) of signed(coeff_width - 1 downto 0);
    signal r_coeff_reg : t_coeff_reg := ( 
        x"006B", x"02F9", x"0A05", x"14E8", x"1DAD", x"1DAD", 
        x"14E8", x"0A05", x"02F9", x"006B"
    );
    
begin

    p_a_pipe: process (i_clk) is
    begin
    if rising_edge(i_clk) then
        if (i_reset = '1') then
            for i in 0 to num_taps - 1 loop
                r_a_pipe(i) <= (others => '0');
            end loop;
            r_a_valid   <= '0';
        else
            for i in 0 to num_taps - 1 loop
                r_a_pipe(i) <= signed(x);
            end loop;
            r_a_valid <= in_valid;
        end if;
    end if;
    end process p_a_pipe;
    
    p_mult: process (i_clk) is
    begin
    if rising_edge(i_clk) then
       if (i_reset = '1') then
            for i in 0 to num_taps - 1 loop
                r_mult_reg(i) <= (others => '0');
            end loop;
            r_mult_valid   <= '0';
        else
            for i in 0 to num_taps - 1 loop
                r_mult_reg(i) <= r_a_pipe(i) * r_coeff_reg(i);
            end loop;
            r_mult_valid <= r_a_valid;
        end if;
    end if;
    end process p_mult;


    p_acum: process (i_clk) is
    begin
    if rising_edge(i_clk) then
        if (i_reset = '1') then
            for i in 0 to num_taps - 1 loop
                r_accum_reg(i) <= (others => '0');
            end loop;
            y <= (others => '0');
            out_valid   <= '0';
        else
            for i in 1 to num_taps - 2 loop
                r_accum_reg(i) <= r_accum_reg(i + 1) + r_mult_reg(i);
            end loop;
            r_accum_reg(num_taps - 1) <= r_mult_reg(num_taps -1);
            -- trucation the fractional part
            y <= std_logic_vector(r_accum_reg(0)(accum_width - 1 downto accum_width - out_width));
            out_valid <= r_mult_valid;
        end if;
    end if;
    end process p_acum;

end rtl;
