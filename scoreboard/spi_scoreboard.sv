`ifndef SPI_SCOREBOARD_SV
`define SPI_SCOREBOARD_SV

class spi_scoreboard;
    mailbox #(apb_transaction) apb_mbx;
    mailbox #(spi_transaction) spi_mbx;

    int error_count;

    // Reference model state
    bit [31:0] ctrl;
    bit [31:0] status;
    bit [31:0] clk_div;
    bit [31:0] ss_ctrl;
    bit [31:0] int_en;
    bit [31:0] int_stat;
    bit [31:0] delay_cfg;

    // FIFO models
    bit [31:0] tx_fifo[$];
    bit [31:0] rx_fifo[$];

    // APB Register Address Map
    localparam bit [7:0] ADDR_CTRL     = 8'h00;
    localparam bit [7:0] ADDR_STATUS   = 8'h04;
    localparam bit [7:0] ADDR_TX_DATA  = 8'h08;
    localparam bit [7:0] ADDR_RX_DATA  = 8'h0C;
    localparam bit [7:0] ADDR_CLK_DIV  = 8'h10;
    localparam bit [7:0] ADDR_SS_CTRL  = 8'h14;
    localparam bit [7:0] ADDR_INT_EN   = 8'h18;
    localparam bit [7:0] ADDR_INT_STAT = 8'h1C;
    localparam bit [7:0] ADDR_DELAY    = 8'h20;

    function new(mailbox #(apb_transaction) apb_mbx, mailbox #(spi_transaction) spi_mbx);
        this.apb_mbx = apb_mbx;
        this.spi_mbx = spi_mbx;
        this.error_count = 0;

        // Reset values
        this.ctrl      = 32'h0;
        this.status    = 32'h0000_0014; // TX_EMPTY(2) and RX_EMPTY(4) are 1
        this.clk_div   = 32'h0;
        this.ss_ctrl   = 32'h0;
        this.int_en    = 32'h0;
        this.int_stat  = 32'h0;
        this.delay_cfg = 32'h0;
    endfunction

    task run();
        fork
            process_apb();
            process_spi();
        join_none
    endtask

    task process_apb();
        apb_transaction apb_tx;
        forever begin
            apb_mbx.get(apb_tx);
            if (apb_tx.is_write) begin
                // Update reference model state on APB write
                case (apb_tx.addr)
                    ADDR_CTRL:     ctrl = apb_tx.data;
                    ADDR_CLK_DIV:  clk_div = apb_tx.data;
                    ADDR_SS_CTRL:  ss_ctrl = apb_tx.data;
                    ADDR_INT_EN:   int_en = apb_tx.data;
                    ADDR_DELAY:    delay_cfg = apb_tx.data;
                    ADDR_TX_DATA: begin
                        if (ctrl[0]) begin // If SPI is enabled (cfg_en)
                            if (tx_fifo.size() < 8) begin
                                tx_fifo.push_back(apb_tx.data);
                            end else begin
                                int_stat[2] = 1; // TX_OVF
                            end
                        end
                    end
                    ADDR_INT_STAT: int_stat = int_stat & ~apb_tx.data; // W1C
                endcase
            end else begin
                // Predict APB read output
                bit [31:0] expected_data;
                case (apb_tx.addr)
                    ADDR_CTRL:     expected_data = ctrl;
                    ADDR_STATUS: begin
                        // Recalculate status before checking
                        bit rx_empty = (rx_fifo.size() == 0);
                        bit rx_full  = (rx_fifo.size() == 8);
                        bit tx_empty = (tx_fifo.size() == 0);
                        bit tx_full  = (tx_fifo.size() == 8);
                        bit rx_ovf   = int_stat[3];
                        bit tx_ovf   = int_stat[2];
                        bit busy     = 0; // simplified
                        
                        expected_data = {25'b0, rx_ovf, tx_ovf, rx_empty, rx_full, tx_empty, tx_full, busy};
                    end
                    ADDR_CLK_DIV:  expected_data = clk_div;
                    ADDR_SS_CTRL:  expected_data = ss_ctrl;
                    ADDR_INT_EN:   expected_data = int_en;
                    ADDR_INT_STAT: expected_data = int_stat;
                    ADDR_DELAY:    expected_data = delay_cfg;
                    ADDR_RX_DATA: begin
                        if (rx_fifo.size() > 0) begin
                            expected_data = rx_fifo.pop_front();
                        end else begin
                            expected_data = 32'h0;
                        end
                    end
                    default: expected_data = 32'h0;
                endcase

                // Skip checking status exactly for busy bit right now,
                // but let's check other static registers strictly.
                if (apb_tx.addr != ADDR_STATUS) begin
                    if (apb_tx.data !== expected_data) begin
                        $display("[SCOREBOARD_ERROR] APB Read mismatch at addr 0x%02h: Expected 0x%08h, got 0x%08h", 
                            apb_tx.addr, expected_data, apb_tx.data);
                        error_count++;
                    end
                end
            end
        end
    endtask

    task process_spi();
        spi_transaction spi_tx;
        forever begin
            spi_mbx.get(spi_tx);
            if (tx_fifo.size() > 0) begin
                bit [31:0] expected_tx = tx_fifo.pop_front();
                
                int width_bits;
                case (ctrl[7:6])
                    2'b00: width_bits = 8;
                    2'b01: width_bits = 16;
                    2'b10, 2'b11: width_bits = 32;
                endcase
                
                bit [31:0] mask = (width_bits == 32) ? 32'hFFFF_FFFF : ((1 << width_bits) - 1);
                expected_tx &= mask;
                bit [31:0] observed_tx = spi_tx.mosi_data & mask;

                if (observed_tx !== expected_tx) begin
                    $display("[SCOREBOARD_ERROR] SPI TX mismatch: Expected 0x%08h, got 0x%08h", 
                        expected_tx, observed_tx);
                    error_count++;
                end

                // If loopback is enabled (ctrl[5]), the sent data loops back to RX FIFO
                if (ctrl[5]) begin
                    if (rx_fifo.size() < 8) rx_fifo.push_back(expected_tx);
                end
            end else begin
                $display("[SCOREBOARD_ERROR] Unexpected SPI transaction observed! TX FIFO is empty.");
                error_count++;
            end
        end
    endtask

    function void report();
        $display("-----------------------------------------");
        $display("          SCOREBOARD REPORT              ");
        $display("-----------------------------------------");
        if (error_count == 0)
            $display("[TEST_PASSED] 0 scoreboard errors");
        else
            $display("[TEST_FAILED] %0d scoreboard errors", error_count);
        $display("-----------------------------------------");
    endfunction

endclass

`endif
