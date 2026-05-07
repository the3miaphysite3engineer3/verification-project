// apb_assertions.sv
// APB assertions bound to the regfile

`ifndef APB_ASSERTIONS_SV
`define APB_ASSERTIONS_SV
`timescale 1ns/1ps

module apb_assertions (
    input wire         PCLK,
    input wire         PRESETn,

    // APB ports
    input wire         PSEL,
    input wire         PENABLE,
    input wire         PWRITE,
    input wire [7:0]   PADDR,
    input wire [31:0]  PWDATA,
    input wire [31:0]  PRDATA,
    input wire         PREADY,
    input wire         PSLVERR,

    // Other regfile ports needed to prevent wildcard bind errors
    input wire         cfg_en,
    input wire         cfg_mstr,
    input wire [1:0]   cfg_mode,
    input wire         cfg_lsb_first,
    input wire         cfg_loopback,
    input wire [1:0]   cfg_width,
    input wire [15:0]  cfg_clk_div,
    input wire [7:0]   cfg_delay,
    input wire [3:0]   SS_n,
    input wire [31:0]  tx_word,
    input wire         tx_empty,
    input wire         tx_pop,
    input wire         rx_push_valid,
    input wire [31:0]  rx_push_data,
    input wire         busy_in,
    input wire         transfer_done_pulse,
    input wire         IRQ
);

    // Rule 1: PENABLE needs PSEL
    property p_penable_requires_psel;
        @(posedge PCLK) disable iff (!PRESETn)
        PENABLE |-> PSEL;
    endproperty
    a_penable_requires_psel: assert property (p_penable_requires_psel)
        else $error("[ASSERTION_ERROR] a_penable_requires_psel - PENABLE asserted without PSEL");

    // Rule 2: SETUP must go to ACCESS
    property p_setup_followed_by_access;
        @(posedge PCLK) disable iff (!PRESETn)
        (PSEL && !PENABLE) |=> (PSEL && PENABLE);
    endproperty
    a_setup_followed_by_access: assert property (p_setup_followed_by_access)
        else $error("[ASSERTION_ERROR] a_setup_followed_by_access - SETUP phase not followed by ACCESS phase");

    // Rule 3: Zero wait state check
    property p_pready_during_access;
        @(posedge PCLK) disable iff (!PRESETn)
        (PSEL && PENABLE) |-> (PREADY === 1'b1);
    endproperty
    a_pready_during_access: assert property (p_pready_during_access)
        else $error("[ASSERTION_ERROR] a_pready_during_access - PREADY not asserted during ACCESS phase");

    // Rule 4: No slave errors
    property p_pslverr_always_zero;
        @(posedge PCLK) disable iff (!PRESETn)
        (PSEL && PENABLE) |-> (PSLVERR === 1'b0);
    endproperty
    a_pslverr_always_zero: assert property (p_pslverr_always_zero)
        else $error("[ASSERTION_ERROR] a_pslverr_always_zero - PSLVERR asserted during ACCESS phase");

    // Rule 5: Address stays the same
    property p_paddr_stable;
        @(posedge PCLK) disable iff (!PRESETn)
        (PSEL && !PENABLE) |=> $stable(PADDR);
    endproperty
    a_paddr_stable: assert property (p_paddr_stable)
        else $error("[ASSERTION_ERROR] a_paddr_stable - PADDR changed between SETUP and ACCESS phases");

    // Rule 6: Direction stays the same
    property p_pwrite_stable;
        @(posedge PCLK) disable iff (!PRESETn)
        (PSEL && !PENABLE) |=> $stable(PWRITE);
    endproperty
    a_pwrite_stable: assert property (p_pwrite_stable)
        else $error("[ASSERTION_ERROR] a_pwrite_stable - PWRITE changed between SETUP and ACCESS phases");

    // Rule 7: Write data stays the same
    property p_pwdata_stable_on_write;
        @(posedge PCLK) disable iff (!PRESETn)
        (PSEL && !PENABLE && PWRITE) |=> $stable(PWDATA);
    endproperty
    a_pwdata_stable_on_write: assert property (p_pwdata_stable_on_write)
        else $error("[ASSERTION_ERROR] a_pwdata_stable_on_write - PWDATA changed during write transaction");

endmodule
`endif