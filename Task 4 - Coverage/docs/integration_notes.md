# Coverage Integration Notes

## Owner

Mohamed Maher  
Coverage task

## Files Added

```text
env/coverage.sv
docs/coverage_plan.md
docs/integration_notes.md
```

## Main Class

```systemverilog
spi_coverage_col
```

The coverage model is implemented in:

```text
env/coverage.sv
```

## Important Note

The coverage file defines the coverage model only.  
It does not collect coverage automatically.

The test owner or integration owner should create an object from the coverage class and call the sampling tasks from the tests.

Example:

```systemverilog
spi_coverage_col cov;

initial begin
    cov = new();
end
```

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

## Example Calls

```systemverilog
cov.sample_config(2'd0, 1'b0, 2'b00, 1'b0);
cov.sample_timing(16'd0, 8'd0);
cov.sample_reg(8'h00, 1'b1, 1'b0, 1'b1);
cov.sample_irq(3'd0, 1'b1, 1'b0, 1'b0);
cov.sample_fifo(0, 0, 1'b0, 1'b0);
cov.sample_error(3'd0);
```

## Test Mapping

| Test | Suggested Coverage Calls |
|---|---|
| sanity_test | sample_config, sample_timing |
| reg_access_test | sample_reg |
| mode_coverage_test | sample_config |
| width_coverage_test | sample_config |
| fifo_stress_test | sample_fifo, sample_irq |
| interrupt_test | sample_irq |
| clk_div_corner_test | sample_timing |
| loopback_test | sample_config |
| delay_transfer_test | sample_timing |
| error_injection_test | sample_error, sample_reg, sample_fifo |

## Compile Note

Please include this file in the environment compile list:

```text
env/coverage.sv
```

Example Makefile entry:

```makefile
ENV_SRCS = env/ref_model.sv env/coverage.sv
```

## Final Note

The final coverage percentage depends on the tests calling the sampling tasks correctly during regression.