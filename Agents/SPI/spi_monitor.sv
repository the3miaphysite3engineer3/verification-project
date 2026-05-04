`ifndef SPI_MONITOR_SV
`define SPI_MONITOR_SV

class spi_monitor;
    virtual spi_if.slave vif;
    mailbox #(spi_transaction) mon2scb;
    spi_config cfg;

    function new(virtual spi_if.slave v, mailbox #(spi_transaction) mb, spi_config c);
        this.vif = v;
        this.mon2scb = mb;
        this.cfg = c;
    endfunction

    task run();
        // DECLARATIONS 
        logic sclk_q;
        int width_bits;
        int bit_idx;
        logic [31:0] shift_reg;
        bit in_transfer;
        logic is_rising;
        logic is_falling;
        logic sample_edge;
        spi_transaction tr;

        //INITIALIZATION
        in_transfer = 0;

        // EXECUTION LOGIC
        forever begin
            @(posedge vif.pclk); // Synchronize to system clock

            // Decode dynamic width
            case(cfg.width_cfg)
                2'b00: width_bits = 8;
                2'b01: width_bits = 16;
                2'b10: width_bits = 32;
                default: width_bits = 8;
            endcase

            if (vif.ss_n == 4'hF) begin
                // Inactive state
                sclk_q = cfg.mode[1]; // Track idle CPOL
                in_transfer = 0;
                shift_reg = 32'h0;
                bit_idx = cfg.lsb_first ? 0 : width_bits - 1;
            end else begin
                // Active transfer state
                if (!in_transfer) in_transfer = 1'b1;

                // ASSIGNMENTS 
                is_rising  = (sclk_q === 1'b0 && vif.sclk === 1'b1);
                is_falling = (sclk_q === 1'b1 && vif.sclk === 1'b0);
                sample_edge = (cfg.mode[1] == cfg.mode[0]) ? is_rising : is_falling;

                if (sample_edge) begin
                    shift_reg[bit_idx] = vif.mosi;

                    // If this is the last bit of the word
                    if ((cfg.lsb_first && bit_idx == width_bits - 1) || 
                        (!cfg.lsb_first && bit_idx == 0)) begin
                        
                        tr = new(); // Instantiate here
                        tr.mosi_data = shift_reg;
                        tr.width     = width_bits;
                        tr.lsb_first = cfg.lsb_first;
                        tr.mode      = cfg.mode;
                        mon2scb.put(tr); // Push to scoreboard
                    end else begin
                        bit_idx = cfg.lsb_first ? bit_idx + 1 : bit_idx - 1;
                    end
                end
                sclk_q = vif.sclk; // Save state for next edge detection
            end
        end
    endtask
endclass

`endif 
