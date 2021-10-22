library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
 
entity conv_tb is
end conv_tb;
 
architecture behave of conv_tb is 

	-- Component Declaration for the Unit Under Test (UUT)
	component conv
		generic(
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
	end component conv;
	
	-- constants
	constant c_width       : natural := 8;
	constant c_kr          : natural := 1;
	constant c_n_elems     : natural := 9;

	--Inputs
	signal ipxvalid        : std_logic := '0';
	signal ipxdata         : std_logic_vector (c_n_elems * c_width - 1 downto 0) := x"020202020202020202";
	signal clk             : std_logic := '0';

	--Outputs
	signal o_data_valid_tb : std_logic;
	signal o_data_tb       : std_logic_vector(c_width - 1 downto 0);

	-- Clock period definitions
	constant clk_period  : time := 10 ns;

	begin

	-- Instantiate the Unit Under Test (UUT)
	uut: conv
	generic map (
		g_width => c_width,
		kernelradius => c_kr,
		n_elems => c_n_elems
		)
	port map (
        i_clk => clk,
        --
        i_pixel_valid => ipxvalid,
        i_pixel_data => ipxdata,
        --
        o_data => o_data_tb,
        o_data_valid => o_data_valid_tb
	);

	-- Clock process definitions
	clk_process :process
	begin
		wait for clk_period/2;
		clk <= not clk;
	end process clk_process;
	
	p_test : process is
	begin
		wait until clk = '1';
		wait until clk = '1';
		wait until clk = '1';
		wait until clk = '1';
		ipxvalid <= '1';
        wait until clk = '1';
        wait until clk = '1';
        wait until clk = '1';
        wait until clk = '1';
        wait until clk = '1';
        wait until clk = '1';
        wait until clk = '1';
        wait until clk = '1';
	end process p_test;
	
end behave;
