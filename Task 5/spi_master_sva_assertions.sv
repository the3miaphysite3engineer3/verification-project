module spi_master_sva (
    input logic PCLK,
    input logic PRESETn,
    input logic PSEL,
    input logic PENABLE,
    input logic PWRITE,
    input logic [7:0] PADDR,
    input logic [31:0] PWDATA,
    input logic SCLK,
    input logic MOSI,
    input logic [3:0] SS_n,
    input logic IRQ,
    input logic BUSY,
    input logic CPOL,
    input logic CPHA,
    input logic [31:0] INT_STAT,
    input logic [31:0] INT_EN,
    input logic TX_FULL,
    input logic RX_FULL,
    input logic TX_OVF,
    input logic RX_OVF
);

    property p_apb_psel_2cycles;
        @(posedge PCLK) disable iff (!PRESETn)
        $rose(PSEL) |=> PSEL;
    endproperty

    property p_apb_penable_psel;
        @(posedge PCLK) disable iff (!PRESETn)
        PENABLE |-> PSEL;
    endproperty

    property p_apb_stable_ctrl;
        @(posedge PCLK) disable iff (!PRESETn)
        $rose(PSEL) |=> $stable(PADDR) && $stable(PWRITE) && ($past(PWRITE) ? $stable(PWDATA) : 1'b1);
    endproperty

    property p_spi_sclk_idle;
        @(posedge PCLK) disable iff (!PRESETn)
        !BUSY |-> (SCLK == CPOL);
    endproperty

    logic is_sample_edge;
    assign is_sample_edge = (CPHA == 1'b0) ? 
        ((CPOL == 1'b0) ? $rose(SCLK) : $fell(SCLK)) : 
        ((CPOL == 1'b0) ? $fell(SCLK) : $rose(SCLK));

    property p_spi_mosi_stable;
        @(posedge PCLK) disable iff (!PRESETn)
        is_sample_edge |-> $stable(MOSI) ##1 $stable(MOSI);
    endproperty

    property p_spi_ssn_held;
        @(posedge PCLK) disable iff (!PRESETn)
        BUSY && $past(BUSY) |-> $stable(SS_n);
    endproperty

    logic tx_push;
    assign tx_push = PSEL && PENABLE && PWRITE && (PADDR == 8'h08);

    property p_fifo_tx_ovf;
        @(posedge PCLK) disable iff (!PRESETn)
        tx_push && TX_FULL |=> TX_OVF;
    endproperty

    logic rx_push;
    assign rx_push = $fell(BUSY);

    property p_fifo_rx_ovf;
        @(posedge PCLK) disable iff (!PRESETn)
        rx_push && RX_FULL |=> RX_OVF;
    endproperty

    property p_irq_comb;
        @(posedge PCLK) disable iff (!PRESETn)
        IRQ == |(INT_STAT & INT_EN);
    endproperty

    assert property (p_apb_psel_2cycles);
    assert property (p_apb_penable_psel);
    assert property (p_apb_stable_ctrl);
    assert property (p_spi_sclk_idle);
    assert property (p_spi_mosi_stable);
    assert property (p_spi_ssn_held);
    assert property (p_fifo_tx_ovf);
    assert property (p_fifo_rx_ovf);
    assert property (p_irq_comb);

endmodule