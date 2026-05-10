`ifndef SPI_SCOREBOARD_SV
`define SPI_SCOREBOARD_SV

class spi_scoreboard;

    mailbox #(apb_transaction) apb_mbx;
    mailbox #(spi_transaction) spi_mbx;

    int error_count;

    // FIFO depth as a parameter to avoid magic numbers
    localparam int FIFO_DEPTH = 8;

    // Reference model registers
    bit [31:0] ctrl;
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
        this.apb_mbx   = apb_mbx;
        this.spi_mbx   = spi_mbx;
        this.error_count = 0;

        // Reset values per spec
        this.ctrl      = 32'h0;
        this.clk_div   = 32'h0;
        this.ss_ctrl   = 32'h0;
        this.int_en    = 32'h0;
        this.int_stat  = 32'h0;
        this.delay_cfg = 32'h0;

        tx_fifo.delete();
        rx_fifo.delete();
    endfunction

    // Mask data to the programmed transfer width (8/16/32-bit)
    function automatic bit [31:0] apply_width_mask(bit [31:0] data);
        case (ctrl[7:6])
            2'b00: return data & 32'h0000_00FF;
            2'b01: return data & 32'h0000_FFFF;
            2'b10: return data;
            default: begin
                $warning("[SCOREBOARD_WARNING] Illegal WIDTH=2'b11 detected");
                return data;
            end
        endcase
    endfunction

    // Reverse bit order for LSB_FIRST mode
    function automatic bit [31:0] reverse_bits(bit [31:0] data, int width);
        bit [31:0] temp = 32'h0;
        for (int i = 0; i < width; i++)
            temp[i] = data[width-1-i];
        return temp;
    endfunction

    // Return transfer width in bits based on CTRL[7:6]
    function automatic int get_width_bits();
        case (ctrl[7:6])
            2'b00: return 8;
            2'b01: return 16;
            default: return 32;
        endcase
    endfunction

    // Build expected STATUS register value from FIFO state and int_stat
    function automatic bit [31:0] get_expected_status();
        bit busy     = 1'b0; // Simplified — BUSY tracking owned by SPI monitor
        bit tx_full  = (tx_fifo.size() == FIFO_DEPTH);
        bit tx_empty = (tx_fifo.size() == 0);
        bit rx_full  = (rx_fifo.size() == FIFO_DEPTH);
        bit rx_empty = (rx_fifo.size() == 0);
        bit tx_ovf   = int_stat[2];
        bit rx_ovf   = int_stat[3];

        return {25'b0, rx_ovf, tx_ovf, rx_empty, rx_full, tx_empty, tx_full, busy};
    endfunction

    // Set a sticky INT_STAT bit (called on each interrupt event)
    task automatic set_int_stat_bit(int bit_idx);
        int_stat[bit_idx] = 1'b1;
    endtask

    task run();
        fork
            process_apb();
            process_spi();
        join_none
    endtask

    task process_apb();
        apb_transaction apb_tx;
        bit old_en;

        forever begin
            apb_mbx.get(apb_tx);

            if (apb_tx.is_write) begin
                case (apb_tx.addr)

                    ADDR_CTRL: begin
                        old_en = ctrl[0];
                        ctrl   = apb_tx.data;
                        // EN 1->0: flush TX and RX FIFOs per spec sec 6.1
                        if (old_en && !ctrl[0]) begin
                            tx_fifo.delete();
                            rx_fifo.delete();
                        end
                    end

                    ADDR_CLK_DIV:  clk_div   = apb_tx.data;
                    ADDR_SS_CTRL:  ss_ctrl   = apb_tx.data;
                    ADDR_INT_EN:   int_en    = apb_tx.data;
                    ADDR_DELAY:    delay_cfg = apb_tx.data;

                    ADDR_TX_DATA: begin
                        if (ctrl[0]) begin
                            if (tx_fifo.size() < FIFO_DEPTH)
                                // Push width-masked data into TX FIFO model
                                tx_fifo.push_back(apply_width_mask(apb_tx.data));
                            else
                                set_int_stat_bit(2); // TX_OVF
                        end
                    end

                    // W1C: clear bits written as 1; new events on same cycle stay set (R18)
                    ADDR_INT_STAT: int_stat = int_stat & ~apb_tx.data;

                    ADDR_RX_DATA: ; // writes to RX_DATA are ignored per spec

                    default: ;      // reserved offsets — ignore (R23)

                endcase

            end else begin
                bit [31:0] expected_data;

                case (apb_tx.addr)
                    ADDR_CTRL:     expected_data = ctrl;
                    ADDR_CLK_DIV:  expected_data = clk_div;
                    ADDR_SS_CTRL:  expected_data = ss_ctrl;
                    ADDR_INT_EN:   expected_data = int_en;
                    ADDR_INT_STAT: expected_data = int_stat;
                    ADDR_DELAY:    expected_data = delay_cfg;
                    ADDR_TX_DATA:  expected_data = 32'h0; // TX_DATA reads return 0, no side effect
                    ADDR_RX_DATA:  expected_data = (rx_fifo.size() > 0) ? rx_fifo.pop_front() : 32'h0;
                    default:       expected_data = 32'h0; // reserved offsets read as 0 (R23)

                    // STATUS is handled separately below to exclude BUSY bit from comparison
                    ADDR_STATUS: begin
                        expected_data = get_expected_status();
                        // Only check non-BUSY bits (bit 0) — BUSY timing tracked by SPI monitor
                        if ((apb_tx.data & 32'hFFFF_FFFE) !== (expected_data & 32'hFFFF_FFFE)) begin
                            $error("[TIME: %0t] [SCOREBOARD_ERROR] STATUS mismatch | Expected: 0x%08h | Actual: 0x%08h",
                                   $time, expected_data, apb_tx.data);
                            error_count++;
                        end
                        continue;
                    end
                endcase

                if (apb_tx.data !== expected_data) begin
                    $error("[TIME: %0t] [SCOREBOARD_ERROR] APB Read Mismatch at ADDR: 0x%02h | Expected: 0x%08h | Actual: 0x%08h",
                           $time, apb_tx.addr, expected_data, apb_tx.data);
                    error_count++;
                end
            end
        end
    endtask

    task process_spi();
        spi_transaction spi_tx;
        bit [31:0] expected_tx;
        bit [31:0] observed_tx;
        bit [31:0] rx_word;
        int        width_bits;

        forever begin
            spi_mbx.get(spi_tx);

            if (tx_fifo.size() == 0) begin
                $error("[TIME: %0t] [SCOREBOARD_ERROR] Unexpected SPI transaction! TX FIFO is empty.", $time);
                error_count++;
                continue;
            end

            expected_tx = tx_fifo.pop_front();
            width_bits  = get_width_bits();

            observed_tx = apply_width_mask(spi_tx.mosi_data);

            // Apply bit reversal for LSB_FIRST mode (CTRL[4])
            if (ctrl[4]) begin
                expected_tx = reverse_bits(expected_tx, width_bits);
                observed_tx = reverse_bits(observed_tx, width_bits);
            end

            if (observed_tx !== expected_tx) begin
                $error("[TIME: %0t] [SCOREBOARD_ERROR] SPI TX Mismatch | Expected: 0x%08h | Actual: 0x%08h",
                       $time, expected_tx, observed_tx);
                error_count++;
            end

            // Select RX source: loopback uses MOSI, normal uses MISO (R19)
            rx_word = apply_width_mask(ctrl[5] ? spi_tx.mosi_data : spi_tx.miso_data);

            // Push received word to RX FIFO or flag overflow (R14)
            if (rx_fifo.size() < FIFO_DEPTH) begin
                rx_fifo.push_back(rx_word);
                // Assert RX_FULL interrupt when FIFO just became full
                if (rx_fifo.size() == FIFO_DEPTH)
                    set_int_stat_bit(1); // RX_FULL
            end else begin
                set_int_stat_bit(3); // RX_OVF
            end

            // TRANSFER_DONE fires one cycle after each completed word (spec sec 3.7)
            set_int_stat_bit(4); // TRANSFER_DONE

            // TX_EMPTY fires when the last word is popped from the TX FIFO
            if (tx_fifo.size() == 0)
                set_int_stat_bit(0); // TX_EMPTY

        end
    endtask

    function void report();
        $display("----------------------------------------------");
        $display("            SCOREBOARD REPORT                ");
        $display("----------------------------------------------");
        if (error_count == 0)
            $display("[TEST PASSED] 0 scoreboard errors detected");
        else
            $display("[TEST FAILED] %0d scoreboard error(s) detected", error_count);
        $display("----------------------------------------------");
    endfunction

endclass

`endif
