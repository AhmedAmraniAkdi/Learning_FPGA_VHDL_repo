library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
 
entity imageControl_tb is
end imageControl_tb;
 
architecture behave of imageControl_tb is 

	-- Component Declaration for the Unit Under Test (UUT)
	component imageControl
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
	end component imageControl;
	
	-- constants
	constant c_width       : natural := 8;
	constant c_n_elems     : natural := 9;

	--Inputs
	signal ipxvalid        : std_logic := '1';
	signal ipxdata         : std_logic_vector (c_width - 1 downto 0) := (others => '0');
	signal clk             : std_logic := '0';
	signal rst             : std_logic := '0';

	--Outputs
	signal o_data_valid_tb : std_logic;
	signal o_data_tb       : std_logic_vector(c_width * c_n_elems - 1 downto 0);
    signal o_intr_tb       : std_logic;
    
	-- Clock period definitions
	constant clk_period  : time := 10 ns;

	begin

	-- Instantiate the Unit Under Test (UUT)
	uut: imageControl
	generic map (
		g_width => c_width,
		n_elems => c_n_elems
		)
	port map (
        i_clk => clk,
        i_rst => rst,
        --
        i_pixel_valid => ipxvalid,
        i_pixel_data => ipxdata,
        --
        o_data => o_data_tb,
        o_data_valid => o_data_valid_tb,
        o_intr => o_intr_tb
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
		rst <= '0';
		-- I'd rather do it in the gui for now, should see a better way to access internal signals
	end process p_test;
	
end behave;
