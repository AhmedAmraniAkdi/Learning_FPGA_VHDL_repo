library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Toplevel_Conv2d is
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
end Toplevel_Conv2d;

architecture Behavioral of Toplevel_Conv2d is

    signal o_imageControl_data: std_logic_vector(71 downto 0);
    signal o_imageControl_data_valid: std_logic;
    signal neg_axi_reset: std_logic;
    
    component output_buffer
      port (
        wr_rst_busy : out std_logic;
        rd_rst_busy : out std_logic;
        s_aclk : in std_logic;
        s_aresetn : in std_logic;
        s_axis_tvalid : in std_logic;
        s_axis_tready : out std_logic;
        s_axis_tdata : in std_logic_vector(7 downto 0);
        m_axis_tvalid : out std_logic;
        m_axis_tready : in std_logic;
        m_axis_tdata : out std_logic_vector(7 downto 0);
        axis_prog_full : out std_logic
      );
    end component;
    
    signal o_convolved_data : std_logic_vector(7 downto 0);
    signal o_convolved_data_valid: std_logic;
    
    signal axis_prog_full: std_logic;

begin

    neg_axi_reset <= not axi_reset_n;

    entity_imageControl: entity work.imageControl
    port map(
        i_clk => axi_clk,
        i_rst => neg_axi_reset,
        --
        i_pixel_valid => i_data_valid,
        i_pixel_data  => i_input,
        --
        o_data        => o_imageControl_data,
        o_data_valid  => o_imageControl_data_valid,
        o_intr        => o_interrupt
    );
    
    entity_conv : entity work.conv
    port map(
        i_clk         => axi_clk,
        --
        i_pixel_valid => o_imageControl_data_valid,
        i_pixel_data  => o_imageControl_data,
        --
        o_data        => o_convolved_data,
        o_data_valid  => o_convolved_data_valid
    );
    
    o_data_ready <= not axis_prog_full; 
    
    output_fifo : output_buffer
      port map (
        wr_rst_busy => open,
        rd_rst_busy => open,
        s_aclk => axi_clk,
        s_aresetn => axi_reset_n,
        s_axis_tvalid => o_convolved_data_valid,
        s_axis_tready => open,
        s_axis_tdata => o_convolved_data,
        m_axis_tvalid => o_data_valid,
        m_axis_tready => i_data_ready,
        m_axis_tdata => o_data,
        axis_prog_full => axis_prog_full
      );
    
end Behavioral;
