// apb_agent.sv
// Top level agent that connects the driver and monitor

`ifndef APB_AGENT_SV
`define APB_AGENT_SV

class apb_agent;
    apb_driver                 drv;
    apb_monitor                mon;
    mailbox #(apb_transaction) mon2scb;

    virtual apb_if.master  vif_master;
    virtual apb_if.monitor vif_monitor;

    function new(virtual apb_if.master vif_m, virtual apb_if.monitor vif_mon, mailbox #(apb_transaction) mbx = null);
        this.vif_master  = vif_m;
        this.vif_monitor = vif_mon;

        // Hook up the scoreboard mailbox
        if (mbx == null)
            this.mon2scb = new();
        else
            this.mon2scb = mbx;
            
        this.drv = new(vif_m);
        this.mon = new(vif_mon, this.mon2scb);
    endfunction

    // Wrappers for the test sequences to use
    task reset_bus();
        drv.reset_bus();
    endtask

    task wait_for_reset();
        drv.wait_for_reset();
    endtask

    task write(input logic [7:0] addr, input logic [31:0] data);
        drv.write(addr, data);
    endtask

    task read(input logic [7:0] addr, output logic [31:0] data);
        drv.read(addr, data);
    endtask

    task drive(apb_transaction tr);
        drv.drive(tr);
    endtask

    task idle_cycle();
        drv.idle_cycle();
    endtask

    // Start the monitor
    task run();
        mon.run();
    endtask

    function void report();
        mon.report();
    endfunction

endclass
`endif