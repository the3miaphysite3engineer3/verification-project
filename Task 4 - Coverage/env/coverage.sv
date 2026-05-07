`ifndef SPI_COVERAGE_SV
`define SPI_COVERAGE_SV

class spi_coverage_col;

    bit [1:0]  cv_mode;
    bit        cv_lsb_first;
    bit [1:0]  cv_width;
    bit [15:0] cv_clk_div;
    bit [7:0]  cv_delay;
    bit        cv_loopback;

    bit [3:0]  cv_reg_addr;
    bit        cv_reg_read;
    bit        cv_reg_write;
    bit        cv_reg_reset_seen;

    bit [2:0]  cv_irq_id;
    bit        cv_irq_event;
    bit        cv_irq_masked;
    bit        cv_irq_cleared;

    int        cv_tx_occ;
    int        cv_rx_occ;
    bit        cv_tx_ovf;
    bit        cv_rx_ovf;

    bit [2:0]  cv_error_case;

    covergroup cg_spi_config;
        option.per_instance = 1;

        cp_mode : coverpoint cv_mode {
            bins mode0 = {2'd0};
            bins mode1 = {2'd1};
            bins mode2 = {2'd2};
            bins mode3 = {2'd3};
        }

        cp_order : coverpoint cv_lsb_first {
            bins msb_first = {1'b0};
            bins lsb_first = {1'b1};
        }

        cp_width : coverpoint cv_width {
            bins width_8  = {2'b00};
            bins width_16 = {2'b01};
            bins width_32 = {2'b10};
            illegal_bins reserved_width = {2'b11};
        }

        cp_loopback : coverpoint cv_loopback {
            bins disabled = {1'b0};
            bins enabled  = {1'b1};
        }

        cx_mode_width_order : cross cp_mode, cp_width, cp_order;
        cx_loopback_width   : cross cp_loopback, cp_width;
    endgroup

    covergroup cg_timing;
        option.per_instance = 1;

        cp_clk_div : coverpoint cv_clk_div {
            bins div_0     = {16'd0};
            bins div_1     = {16'd1};
            bins div_2     = {16'd2};
            bins div_3     = {16'd3};
            bins div_255   = {16'd255};
            bins div_1024  = {16'd1024};
            bins div_max   = {16'hffff};
            bins div_small = {[16'd4:16'd254]};
            bins div_mid   = {[16'd256:16'd1023]};
            bins div_large = {[16'd1025:16'hfffe]};
        }

        cp_delay : coverpoint cv_delay {
            bins delay_0     = {8'd0};
            bins delay_1     = {8'd1};
            bins delay_small = {[8'd2:8'd31]};
            bins delay_mid   = {[8'd32:8'd127]};
            bins delay_large = {[8'd128:8'd255]};
        }
    endgroup

    covergroup cg_registers;
        option.per_instance = 1;

        cp_reg : coverpoint cv_reg_addr {
            bins CTRL     = {4'h0};
            bins STATUS   = {4'h1};
            bins TX_DATA  = {4'h2};
            bins RX_DATA  = {4'h3};
            bins CLK_DIV  = {4'h4};
            bins SS_CTRL  = {4'h5};
            bins INT_EN   = {4'h6};
            bins INT_STAT = {4'h7};
            bins DELAY    = {4'h8};
            bins RESERVED = {[4'h9:4'hf]};
        }

        cp_read : coverpoint cv_reg_read {
            bins read = {1'b1};
        }

        cp_write : coverpoint cv_reg_write {
            bins write = {1'b1};
        }

        cp_reset_seen : coverpoint cv_reg_reset_seen {
            bins reset_seen = {1'b1};
        }

        cx_reg_read  : cross cp_reg, cp_read;
        cx_reg_write : cross cp_reg, cp_write;
    endgroup

    covergroup cg_interrupts;
        option.per_instance = 1;

        cp_irq_id : coverpoint cv_irq_id {
            bins TX_EMPTY      = {3'd0};
            bins RX_FULL       = {3'd1};
            bins TX_OVF        = {3'd2};
            bins RX_OVF        = {3'd3};
            bins TRANSFER_DONE = {3'd4};
        }

        cp_irq_event : coverpoint cv_irq_event {
            bins seen = {1'b1};
        }

        cp_irq_masked : coverpoint cv_irq_masked {
            bins seen = {1'b1};
        }

        cp_irq_cleared : coverpoint cv_irq_cleared {
            bins seen = {1'b1};
        }

        cx_irq_event   : cross cp_irq_id, cp_irq_event;
        cx_irq_masked  : cross cp_irq_id, cp_irq_masked;
        cx_irq_cleared : cross cp_irq_id, cp_irq_cleared;
    endgroup

    covergroup cg_fifo;
        option.per_instance = 1;

        cp_tx_occ : coverpoint cv_tx_occ {
            bins empty       = {0};
            bins one         = {1};
            bins mid         = {4};
            bins almost_full = {7};
            bins full        = {8};
        }

        cp_rx_occ : coverpoint cv_rx_occ {
            bins empty       = {0};
            bins one         = {1};
            bins mid         = {4};
            bins almost_full = {7};
            bins full        = {8};
        }

        cp_tx_ovf : coverpoint cv_tx_ovf {
            bins overflow_seen = {1'b1};
        }

        cp_rx_ovf : coverpoint cv_rx_ovf {
            bins overflow_seen = {1'b1};
        }
    endgroup

    covergroup cg_error_cases;
        option.per_instance = 1;

        cp_error_case : coverpoint cv_error_case {
            bins reserved_access = {3'd0};
            bins illegal_width   = {3'd1};
            bins rx_empty_read   = {3'd2};
            bins tx_full_write   = {3'd3};
            bins rx_full_push    = {3'd4};
        }
    endgroup

    function new();
        cg_spi_config  = new();
        cg_timing      = new();
        cg_registers   = new();
        cg_interrupts  = new();
        cg_fifo        = new();
        cg_error_cases = new();
    endfunction

    task sample_config(input bit [1:0] mode,
                       input bit       lsb_first,
                       input bit [1:0] width,
                       input bit       loopback);
        cv_mode      = mode;
        cv_lsb_first = lsb_first;
        cv_width     = width;
        cv_loopback  = loopback;
        cg_spi_config.sample();
    endtask

    task sample_timing(input bit [15:0] clk_div,
                       input bit [7:0]  delay_value);
        cv_clk_div = clk_div;
        cv_delay   = delay_value;
        cg_timing.sample();
    endtask

    task sample_reg(input bit [7:0] addr,
                    input bit       is_read,
                    input bit       is_write,
                    input bit       reset_seen);
        cv_reg_addr       = addr[5:2];
        cv_reg_read       = is_read;
        cv_reg_write      = is_write;
        cv_reg_reset_seen = reset_seen;
        cg_registers.sample();
    endtask

    task sample_irq(input bit [2:0] irq_id,
                    input bit       event_seen,
                    input bit       masked_seen,
                    input bit       cleared_seen);
        cv_irq_id      = irq_id;
        cv_irq_event   = event_seen;
        cv_irq_masked  = masked_seen;
        cv_irq_cleared = cleared_seen;
        cg_interrupts.sample();
    endtask

    task sample_fifo(input int tx_occ,
                     input int rx_occ,
                     input bit tx_ovf,
                     input bit rx_ovf);
        cv_tx_occ = tx_occ;
        cv_rx_occ = rx_occ;
        cv_tx_ovf = tx_ovf;
        cv_rx_ovf = rx_ovf;
        cg_fifo.sample();
    endtask

    task sample_error(input bit [2:0] error_case);
        cv_error_case = error_case;
        cg_error_cases.sample();
    endtask

    function void report();
        $display("[COVERAGE] spi_config  = %0.2f%%", cg_spi_config.get_coverage());
        $display("[COVERAGE] timing      = %0.2f%%", cg_timing.get_coverage());
        $display("[COVERAGE] registers   = %0.2f%%", cg_registers.get_coverage());
        $display("[COVERAGE] interrupts  = %0.2f%%", cg_interrupts.get_coverage());
        $display("[COVERAGE] fifo        = %0.2f%%", cg_fifo.get_coverage());
        $display("[COVERAGE] error_cases = %0.2f%%", cg_error_cases.get_coverage());
    endfunction

endclass

`endif