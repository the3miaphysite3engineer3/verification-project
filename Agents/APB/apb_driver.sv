// apb_driver.sv
// Wiggles the pins for the zero wait-state APB protocol

`ifndef APB_DRIVER_SV
`define APB_DRIVER_SV

class apb_driver;
    virtual apb_if.master vif;

    function new(virtual apb_if.master vif);
        this.vif = vif;
    endfunction

    // Reset everything to 0
    task reset_bus();
        vif.cb_master.psel    <= 1'b0;
        vif.cb_master.penable <= 1'b0;
        vif.cb_master.pwrite  <= 1'b0;
        vif.cb_master.paddr   <= '0;
        vif.cb_master.pwdata  <= '0;
    endtask

    // Wait until presetn goes high
    task wait_for_reset();
        wait (vif.presetn === 1'b1);
        @(vif.cb_master);
    endtask

    // 2-cycle write
    task write(input logic [7:0] addr, input logic [31:0] data);
        // SETUP
        vif.cb_master.psel    <= 1'b1;
        vif.cb_master.penable <= 1'b0;
        vif.cb_master.pwrite  <= 1'b1;
        vif.cb_master.paddr   <= addr;
        vif.cb_master.pwdata  <= data;

        @(vif.cb_master); 

        // ACCESS
        vif.cb_master.penable <= 1'b1;
        @(vif.cb_master); 

        // Back to idle
        vif.cb_master.psel    <= 1'b0;
        vif.cb_master.penable <= 1'b0;
    endtask

    // 2-cycle read
    task read(input logic [7:0] addr, output logic [31:0] data);
        // SETUP
        vif.cb_master.psel    <= 1'b1;
        vif.cb_master.penable <= 1'b0;
        vif.cb_master.pwrite  <= 1'b0;
        vif.cb_master.paddr   <= addr;
        vif.cb_master.pwdata  <= '0;

        @(vif.cb_master); 

        // ACCESS
        vif.cb_master.penable <= 1'b1;
        @(vif.cb_master); 

        data = vif.cb_master.prdata;
        
        // Back to idle
        vif.cb_master.psel    <= 1'b0;
        vif.cb_master.penable <= 1'b0;
    endtask

    // Helper to drive directly from a transaction
    task drive(apb_transaction tr);
        if (tr.is_write)
            write(tr.addr, tr.data);
        else
            read(tr.addr, tr.data);
    endtask

    task idle_cycle();
        vif.cb_master.psel    <= 1'b0;
        vif.cb_master.penable <= 1'b0;
        @(vif.cb_master);
    endtask

endclass
`endif