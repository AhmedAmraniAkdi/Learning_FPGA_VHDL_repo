-- fifo testbench
-- simple testbench that just initialises stuff, there isn't much to test but the warping.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
 
entity linebuffer_tb is
end linebuffer_tb;
 
architecture behave of linebuffer_tb is 

	-- Component Declaration for the Unit Under Test (UUT)
	component linebuffer
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
	end component linebuffer;
	
	-- constants
	constant c_width       : natural := 8;
	constant c_kr          : natural := 1;
	constant c_depth       : natural := 512;

	--Inputs
	signal ipxvalid        : std_logic := '0';
	signal ipxdata         : std_logic_vector (c_width - 1 downto 0) := 8D"5";
	signal ireaddata       : std_logic := '0';
	signal clk             : std_logic := '0';
	signal rst             : std_logic := '0';

	--Outputs
	signal o_data_tb       : std_logic_vector((c_kr * 2 + 1) * c_width - 1 downto 0);

	-- Clock period definitions
	constant clk_period  : time := 10 ns;

	begin

	-- Instantiate the Unit Under Test (UUT)
	uut: linebuffer
	generic map (
		g_width => c_width,
		kernelradius => c_kr,
		g_depth => c_depth
		)
	port map (
        i_clk => clk,
        i_rst => rst,
        --
        i_data_valid => ipxvalid,
        i_data => ipxdata,
        i_read_data => ireaddata,
        --
        o_data => o_data_tb
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
		ireaddata <= '1';
		rst <= '0';
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