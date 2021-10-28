library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use STD.textio.all;
use ieee.std_logic_textio.all;
use std.env.finish;


entity pipelined_transposed_fir_tb is
end pipelined_transposed_fir_tb;

architecture Behave of pipelined_transposed_fir_tb is

    -- component declaration for UUT
    component pipelined_transposed_fir is
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
    end component pipelined_transposed_fir;
    
    constant c_in_width   : natural := 16;
    constant c_coeff_width: natural := 16;
    constant c_out_width  : natural := 16;
    constant c_num_taps   : natural := 10;
            
    constant c_multiply_width: natural := 31;
    constant c_accum_width   : natural := 35;
    
    constant clk_period      : time := 10 ns; 
    constant conv_width      : natural := 98;

            -- in
    signal r_clk      : std_logic := '0';
    signal r_reset    : std_logic := '1';
    signal r_x        : std_logic_vector(c_in_width - 1 downto 0) := (others => '0');
    signal r_in_valid : std_logic := '0';
            -- out
    signal r_y        : std_logic_vector(c_out_width -1 downto 0);
    signal r_out_valid: std_logic;
    
    file wave_file : text open read_mode is "inputWave.txt";
    
begin

	-- Instantiate the Unit Under Test (UUT)
	uut: pipelined_transposed_fir
        generic map(
            in_width       => c_in_width,
            coeff_width    => c_coeff_width,
            out_width      => c_out_width,
            num_taps       => c_num_taps,
            multiply_width => c_multiply_width,
            accum_width    => c_accum_width   
        )
        port map(
            i_clk          => r_clk,
            i_reset        => r_reset,
            x              => r_x,
            in_valid       => r_in_valid,
            y              => r_y,
            out_valid      => r_out_valid
        );
        
	-- Clock process definitions
	clk_process : process
	begin
		wait for clk_period/2;
		r_clk  <= not r_clk ;
	end process clk_process;
	
	-- test process
	p_input : process
      variable input_line : line;
      variable input : std_logic_vector(c_in_width - 1 downto 0);
	begin
	
	wait for 100ns;
	r_reset <= '1';
	wait for 100ns;
	r_reset <= '0';
	
	while not endfile(wave_file) loop
	   wait until r_clk = '1';
       readline(wave_file, input_line);
       hread(input_line, input);
       r_x <= input;
       r_in_valid <= '1';
    end loop;
    
    file_close(wave_file);
    
	end process p_input;
	
    p_output : process (r_clk) is
	  file output_file : text open read_mode is "outputWave.txt";
	  variable output_line : line;
      variable output : integer;--std_logic_vector(c_out_width - 1 downto 0);
      variable received : natural := 0;
	begin
	
	if rising_edge(r_clk) then
	   if(r_out_valid = '1') then
	       output := to_integer(unsigned(r_y)); 
	       write(output_line, output, right, c_out_width);
           writeline(output_file, output_line);
           received := received + 1;
           if(received = conv_width) then
              file_close(output_file);
              file_close(wave_file);
              report "simulation finished";
              finish;
           end if;
	   end if;
	end if;
    
	end process p_output;

end Behave;
