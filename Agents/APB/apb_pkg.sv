// apb_pkg.sv
// Includes all the APB files so we only have to compile this one

`ifndef APB_PKG_SV
`define APB_PKG_SV

`include "tb/agents/apb/apb_transaction.sv"
`include "tb/agents/apb/apb_driver.sv"
`include "tb/agents/apb/apb_monitor.sv"
`include "tb/agents/apb/apb_agent.sv"

`endif