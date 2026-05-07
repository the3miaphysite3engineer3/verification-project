// apb_transaction.sv
// Holds the data for APB transfers

`ifndef APB_TRANSACTION_SV
`define APB_TRANSACTION_SV

class apb_transaction;
    rand bit [7:0]   addr;      
    rand bit [31:0]  data;
    rand bit         is_write; // 1 for write, 0 for read

    // Register addresses
    localparam bit [7:0] ADDR_CTRL     = 8'h00;
    localparam bit [7:0] ADDR_STATUS   = 8'h04;
    localparam bit [7:0] ADDR_TX_DATA  = 8'h08;
    localparam bit [7:0] ADDR_RX_DATA  = 8'h0C;
    localparam bit [7:0] ADDR_CLK_DIV  = 8'h10;
    localparam bit [7:0] ADDR_SS_CTRL  = 8'h14;
    localparam bit [7:0] ADDR_INT_EN   = 8'h18;
    localparam bit [7:0] ADDR_INT_STAT = 8'h1C;
    localparam bit [7:0] ADDR_DELAY    = 8'h20;

    // Only generate valid register addresses
    constraint c_valid_addr {
        addr inside {ADDR_CTRL, ADDR_STATUS, ADDR_TX_DATA, ADDR_RX_DATA,
                     ADDR_CLK_DIV, ADDR_SS_CTRL, ADDR_INT_EN, ADDR_INT_STAT,
                     ADDR_DELAY};
    }

    // Prevent writing to RO or reading from WO registers
    constraint c_access_direction {
        (addr == ADDR_STATUS)  -> (is_write == 1'b0);
        (addr == ADDR_TX_DATA) -> (is_write == 1'b1);
        (addr == ADDR_RX_DATA) -> (is_write == 1'b0);
    }

    // Print info for debugging
    function void display(string prefix = "");
        if (is_write)
            $display("%s Wrote %h to addr %h", prefix, data, addr);
        else
            $display("%s Read %h from addr %h", prefix, data, addr);
    endfunction

    // Copy function for the monitor
    function apb_transaction copy();
        apb_transaction c = new();
        c.addr     = this.addr;
        c.data     = this.data;
        c.is_write = this.is_write;
        return c;
    endfunction

endclass
`endif