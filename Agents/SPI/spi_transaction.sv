`ifndef SPI_TRANSACTION_SV
`define SPI_TRANSACTION_SV

class spi_transaction;
    bit [31:0] mosi_data;
    int        width;
    bit        lsb_first;
    bit [1:0]  mode;

    function void print(string name = "SPI_TX");
        $display("[%s] Width: %0d, MOSI: 0x%08h", name, width, mosi_data);
    endfunction
endclass

`endif 
