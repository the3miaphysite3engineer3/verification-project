// apb_monitor.sv
// Passively watches the bus and sends data to the scoreboard

`ifndef APB_MONITOR_SV
`define APB_MONITOR_SV

class apb_monitor;
    virtual apb_if.monitor vif;
    mailbox #(apb_transaction) mon2scb;

    int num_writes;
    int num_reads;

    function new(virtual apb_if.monitor vif, mailbox #(apb_transaction) mbx);
        this.vif      = vif;
        this.mon2scb  = mbx;
        this.num_writes = 0;
        this.num_reads  = 0;
    endfunction

    // Main loop to grab transactions
    task run();
        apb_transaction tr;
        
        wait (vif.presetn === 1'b1);

        forever begin
            @(vif.cb_monitor);
            
            // Capture when transaction is complete
            if (vif.cb_monitor.psel && vif.cb_monitor.penable && vif.cb_monitor.pready) begin
                tr = new();
                tr.addr     = vif.cb_monitor.paddr;
                tr.is_write = vif.cb_monitor.pwrite;
                
                if (tr.is_write) begin
                    tr.data = vif.cb_monitor.pwdata;
                    num_writes++;
                end else begin
                    tr.data = vif.cb_monitor.prdata;
                    num_reads++;
                end

                mon2scb.put(tr);
            end
        end
    endtask

    function void report();
        $display("APB Monitor stats -> Writes: %0d, Reads: %0d", num_writes, num_reads);
    endfunction

endclass
`endif