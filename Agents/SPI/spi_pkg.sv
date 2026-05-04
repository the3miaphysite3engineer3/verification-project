`ifndef SPI_PKG_SV
`define SPI_PKG_SV

package spi_pkg;
    `include "spi_config.sv"
    `include "spi_transaction.sv"
    `include "spi_monitor.sv"
    `include "spi_slave_model.sv"
    `include "spi_agent.sv"
endpackage

`endif 
