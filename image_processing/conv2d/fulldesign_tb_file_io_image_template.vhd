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

    signal    clk             : std_logic;
    signal    axi_reset_n_tb  : std_logic;
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
    
    -- https://vhdlwhiz.com/read-bmp-file/
    type char_file is file of character;
    
    type header_type  is array (0 to header_size - 1) of character;
    
    -- well, we know the sizes, no need for dynamic pointers, no?
    
    type row_type is array (natural range <>) of std_logic_vector(7 downto 0);
    type row_pointer is access row_type;
    
    type image_type is array (natural range <>) of row_pointer;
    type image_pointer is access image_type;
    
    
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
	
	p_test : process is
	-- file vars
    file input_img  : char_file open read_mode is "lena_gray.bmp";
    file output_img : char_file open write_mode is "lena_gray_blurred.bmp";
    variable header: header_type;
    variable row: row_pointer;
    variable image: image_pointer;
    variable char: character;
    
    begin
    
    for i in header_type'range loop
        read(input_img, header(i));
    end loop;
    
        -- Check ID field
--    assert header(0) = 'B' and header(1) = 'M'
--      report "First two bytes are not ""BM"". This is not a BMP file"
--      severity failure;
     
--    -- Check that the pixel array offset is as expected
--    assert character'pos(header(10)) = 54 and
--      character'pos(header(11)) = 0 and
--      character'pos(header(12)) = 0 and
--      character'pos(header(13)) = 0
--      report "Pixel array offset in header is not 54 bytes" -- 436h offset = 1078
--      severity failure;
     
--    -- Check that DIB header size is 40 bytes,
--    -- meaning that the BMP is of type BITMAPINFOHEADER
--    assert character'pos(header(14)) = 40 and
--      character'pos(header(15)) = 0 and
--      character'pos(header(16)) = 0 and
--      character'pos(header(17)) = 0
--      report "DIB headers size is not 40 bytes, is this a Windows BMP?"
--      severity failure;
     
--    -- Check that the number of color planes is 1
--    assert character'pos(header(26)) = 1 and
--      character'pos(header(27)) = 0
--      report "Color planes is not 1" severity failure;
     
--    -- Check that the number of bits per pixel is 8
--    assert character'pos(header(28)) = 8 and
--      character'pos(header(29)) = 0
--      report "Bits per pixel is not 8" severity failure;

    -- Create a new image type in dynamic memory
    image := new image_type (0 to img_size - 1);
    
    for row_i in 0 to img_size - 1 loop
      row := new row_type (0 to img_size - 1);
      for col_i in 0 to img_size - 1 loop
        read(input_img, char);
        row(col_i) := std_logic_vector(to_unsigned(character'pos(char), 8)); -- char to ascii
      end loop;
      image(row_i) := row;
    end loop;
    
    -- we read the image, now we process
    
    
    -- write results
    for i in header_type'range loop
      write(output_img, header(i));
    end loop;
    
    
    for row_i in 0 to img_size - 1 loop
      row := image(row_i);
      for col_i in 0 to img_size - 1 loop
        write(output_img, character'val(to_integer(unsigned(row(col_i))))); -- ascii to char
      end loop;
      deallocate(row); 
    end loop;
    
    deallocate(image);
     
    file_close(input_img);
    file_close(output_img);
     
    report "Simulation done. Check ""lena_gray_blurred.bmp"" image.";
    finish;
    
	end process p_test;
	
end behave;