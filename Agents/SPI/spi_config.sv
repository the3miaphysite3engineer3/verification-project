`ifndef SPI_CONFIG_SV
`define SPI_CONFIG_SV

class spi_config;
    // Mirrored APB registers
    bit [1:0]  mode      = 2'b00;         // {CPOL, CPHA}
    bit [1:0]  width_cfg = 2'b00;         // 00=8b, 01=16b, 10=32b
    bit        lsb_first = 1'b0;          // 1=LSB-first, 0=MSB-first
    bit [31:0] miso_word = 32'h0000_00A5; // Pattern to drive back
endclass

`endif 
