`ifndef SPI_AGENT_SV
`define SPI_AGENT_SV

class spi_agent;
    spi_monitor     mon;
    spi_slave_model slave;

    function new(virtual spi_if.slave vif, mailbox #(spi_transaction) mb, spi_config c);
        mon   = new(vif, mb, c);
        slave = new(vif, c);
    endfunction

    task run();
        fork
            mon.run();
            slave.run();
        join_none
    endtask
endclass

`endif 
