# SPI Master Coverage Plan

## Owner

Mohamed Maher  
Coverage task

## File

The coverage model is implemented in:

```text
env/coverage.sv
```

The main class is:

```systemverilog
spi_coverage_col
```

This file adds the functional coverage model for the SPI Master verification environment.  
The tests should instantiate this class and call the sampling tasks after each related scenario.

---

## 1. SPI Configuration Coverage

Covergroup:

```systemverilog
cg_spi_config
```

This covergroup covers:

```text
- SPI modes: 0, 1, 2, 3
- bit order: MSB-first and LSB-first
- transfer width: 8-bit, 16-bit, 32-bit
- loopback enabled and disabled
```

Important crosses:

```text
mode x width x bit_order
loopback x width
```

The main configuration target is:

```text
4 modes x 3 widths x 2 bit orders = 24 combinations
```

Expected tests:

```text
sanity_test
mode_coverage_test
width_coverage_test
loopback_test
```

---

## 2. Timing Coverage

Covergroup:

```systemverilog
cg_timing
```

This covergroup covers important `CLK_DIV` values:

```text
0, 1, 2, 3, 255, 1024, 65535
```

It also covers delay ranges:

```text
delay = 0
delay = 1
small delay
mid delay
large delay
```

Expected tests:

```text
clk_div_corner_test
delay_transfer_test
```

---

## 3. Register Coverage

Covergroup:

```systemverilog
cg_registers
```

This covergroup covers all visible registers:

```text
CTRL
STATUS
TX_DATA
RX_DATA
CLK_DIV
SS_CTRL
INT_EN
INT_STAT
DELAY
reserved address range
```

It also tracks:

```text
register read
register write
reset value observed
```

Expected tests:

```text
reg_access_test
error_injection_test
```

---

## 4. Interrupt Coverage

Covergroup:

```systemverilog
cg_interrupts
```

This covergroup covers the five interrupt sources:

```text
0 = TX_EMPTY
1 = RX_FULL
2 = TX_OVF
3 = RX_OVF
4 = TRANSFER_DONE
```

For each interrupt source, the coverage model can sample:

```text
event seen
masked event seen
cleared by W1C
```

Expected tests:

```text
interrupt_test
fifo_stress_test
error_injection_test
```

---

## 5. FIFO Coverage

Covergroup:

```systemverilog
cg_fifo
```

This covergroup covers TX and RX FIFO occupancy:

```text
empty
one entry
mid level
almost full
full
```

It also covers:

```text
TX overflow
RX overflow
```

Expected tests:

```text
fifo_stress_test
error_injection_test
```

---

## 6. Error Case Coverage

Covergroup:

```systemverilog
cg_error_cases
```

This covergroup covers important corner/error cases:

```text
0 = reserved register access
1 = illegal width configuration
2 = RX empty read
3 = TX full write
4 = RX full push
```

Expected test:

```text
error_injection_test
```

---

## Sampling Tasks

The coverage class provides these tasks:

```systemverilog
sample_config(mode, lsb_first, width, loopback)
sample_timing(clk_div, delay_value)
sample_reg(addr, is_read, is_write, reset_seen)
sample_irq(irq_id, event_seen, masked_seen, cleared_seen)
sample_fifo(tx_occ, rx_occ, tx_ovf, rx_ovf)
sample_error(error_case)
```

Example usage:

```systemverilog
spi_coverage_col cov;

initial begin
    cov = new();
end
```

Then tests can call the needed task after driving each scenario.

Example:

```systemverilog
cov.sample_config(2'd0, 1'b0, 2'b00, 1'b0);
cov.sample_timing(16'd0, 8'd0);
cov.sample_irq(3'd0, 1'b1, 1'b0, 1'b0);
```

---

## Notes for Integration

The coverage model does not collect coverage automatically.  
The test owner must call the sampling tasks from the tests.

The file should be included in the compile list:

```text
env/coverage.sv
```

The final coverage result depends on the tests calling these sampling tasks correctly during regression.

The project target is at least 85% functional coverage after running the full regression.