library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use STD.textio.all;
use ieee.std_logic_textio.all;
use std.env.finish;
 
entity fulldesign_tb is
end fulldesign_tb;
 
architecture behave of fulldesign_tb is 

	-- Component Declaration for the Unit Under Test (UUT)
	component Toplevel_Conv2d
        Port (
        axi_clk      : in std_logic;
        axi_reset_n  : in std_logic;
        -- slave interface
        i_data_valid : in std_logic;
        i_input      : in std_logic_vector(7 downto 0);
        o_data_ready : out std_logic;
        -- master interface
        o_data_valid : out std_logic;
        o_data       : out std_logic_vector(7 downto 0);
        i_data_ready: in std_logic;
        -- interrupt
        o_interrupt  : out std_logic
     );
	end component Toplevel_Conv2d;

    signal    clk             : std_logic := '0';
    signal    axi_reset_n_tb  : std_logic := '0';
        -- slave interface
    signal    i_data_valid_tb : std_logic;
    signal    i_input_tb      : std_logic_vector(7 downto 0);
    signal    o_data_ready_tb : std_logic;
        -- master interface
    signal    o_data_valid_tb : std_logic;
    signal    o_data_tb       : std_logic_vector(7 downto 0);
    signal    i_data_ready_tb : std_logic := '1';
        -- interrupt
    signal    o_interrupt_tb  :  std_logic;
    
    constant clk_period       : time := 10 ns;
   
   -- file io 
    
    constant img_size         : natural := 512; -- no need to get size from header on our case
    constant header_size      : natural := 1078; -- same
    type char_file is file of character;
    file input_img    : char_file open read_mode is "lena_gray.bmp";
    file output_img   : char_file open write_mode is "lena_gray_blurred.bmp";
    
    -- https://vhdlwhiz.com/read-bmp-file/
    -- https://www.nandland.com/vhdl/examples/example-file-io.html

    
	begin

	-- Instantiate the Unit Under Test (UUT)
	uut: Toplevel_Conv2d
        Port map (
        axi_clk      => clk,
        axi_reset_n  => axi_reset_n_tb,
        -- slave interface
        i_data_valid => i_data_valid_tb,
        i_input      => i_input_tb,
        o_data_ready => o_data_ready_tb,
        -- master interface
        o_data_valid => o_data_valid_tb,
        o_data       => o_data_tb,
        i_data_ready => i_data_ready_tb,
        -- interrupt
        o_interrupt  => o_interrupt_tb
	);


	-- Clock process definitions
	clk_process : process
	begin
		wait for clk_period/2;
		clk  <= not clk ;
	end process clk_process;
	
	
	p_send_input : process is
	-- file vars
    variable char     : character;
    variable sentsize : natural := 0;
    
    begin
    
        wait for 100ns;
        axi_reset_n_tb <= '1';
        wait for 100ns;
        
        -- write header, it's the same for both images
        for i in 0 to header_size - 1 loop
            read(input_img, char);
            write(output_img, char);
        end loop;
        
        report "header written";
        
        -- first row needs to be 0
        for i in 0 to img_size - 1 loop
            wait until clk = '1';
            i_input_tb <= (others => '0');
            i_data_valid_tb <= '1';
        end loop;
        
        -- we continue with the 3 first rows filling all 4 linebuffers
        for i in 0 to img_size * 3 - 1 loop
            wait until clk = '1';
            read(input_img, char);
            i_input_tb <= std_logic_vector(to_unsigned(character'pos(char), 8));
        end loop;
    
        wait until clk = '1';
        i_data_valid_tb <= '0';
        sentsize := sentsize + img_size * 3;
        
        report "all linebuffers are full for the first time";
        
        -- send line by line, wait for interrupt that signals a buffer is free before sending data
        while(sentsize < img_size*img_size) loop
            wait until o_interrupt_tb = '1';
            for i in 0 to img_size - 1 loop
                wait until clk = '1';
                read(input_img, char);
                i_input_tb <= std_logic_vector(to_unsigned(character'pos(char), 8));
                i_data_valid_tb <= '1';
            end loop;
        
            wait until clk = '1';
            i_data_valid_tb <= '0';
            sentsize := sentsize + img_size;
        
        end loop;
        
        wait until clk = '1';
        i_data_valid_tb <= '0';
        
        -- send last 0 line for bottom border conv
        wait until o_interrupt_tb = '1';
        for i in 0 to img_size - 1 loop
            wait until clk = '1';
            i_input_tb <= (others => '0');
            i_data_valid_tb <= '1';
        end loop;
        
        wait until clk = '1';
        i_data_valid_tb <= '0';
        
        wait; 
        -- the hmed factor coming in clutch , what happened is we read the whole image but we are still processing output, 
        -- this process reruns again but since we are at end of file, an error happens! wait fixes it!!
    
    end process p_send_input;
    
   	p_receive_output : process(clk) is
	-- file vars
    variable char     : character;
    variable receivesize : natural := 0;
    
    begin
    
        if rising_edge(clk) then
            if(o_data_valid_tb = '1') then
                char := character'val(to_integer(unsigned(o_data_tb)));
                write(output_img, char);
                receivesize := receivesize + 1;
            end if;
            if(receivesize = img_size*img_size) then
                file_close(output_img);
                file_close(input_img);
                report "Simulation done. Check ""lena_gray_blurred.bmp"" image.";
                finish;
            end if;
        
        end if;
    
    end process p_receive_output; 
    

end behave;