`ifndef SPI_SLAVE_MODEL_SV
`define SPI_SLAVE_MODEL_SV

class spi_slave_model;
    virtual spi_if.slave vif;
    spi_config cfg;

    function new(virtual spi_if.slave v, spi_config c);
        this.vif = v;
        this.cfg = c;
    endfunction

    task run();
        // DECLARATIONS 
        logic sclk_q;
        int width_bits;
        int bit_idx;
        logic is_rising;
        logic is_falling;
        logic launch_edge;

        // INITIALIZATION
        vif.cb_slave.miso <= 1'b0;

        // EXECUTION LOGIC
        forever begin
            @(posedge vif.pclk);

            case(cfg.width_cfg)
                2'b00: width_bits = 8;
                2'b01: width_bits = 16;
                2'b10: width_bits = 32;
                default: width_bits = 8;
            endcase

            if (vif.ss_n == 4'hF) begin
                // Inactive state
                sclk_q = cfg.mode[1];
                bit_idx = cfg.lsb_first ? 0 : width_bits - 1;
                
                // If CPHA=0, launch occurs before the first clock edge
                vif.cb_slave.miso <= cfg.miso_word[bit_idx];
            end else begin
                // Active state
                
                // ASSIGNMENTS 
                is_rising  = (sclk_q === 1'b0 && vif.sclk === 1'b1);
                is_falling = (sclk_q === 1'b1 && vif.sclk === 1'b0);
                launch_edge = (cfg.mode[1] == cfg.mode[0]) ? is_falling : is_rising;

                if (launch_edge) begin
                    if (cfg.lsb_first) 
                        bit_idx = (bit_idx == width_bits - 1) ? 0 : bit_idx + 1;
                    else               
                        bit_idx = (bit_idx == 0) ? width_bits - 1 : bit_idx - 1;

                    vif.cb_slave.miso <= cfg.miso_word[bit_idx];
                end
                sclk_q = vif.sclk;
            end
        end
    endtask
endclass

`endif 
