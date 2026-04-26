# SPI Master Verification Project Plan

## 1. Fixed Verification Harness

The repository already includes a fixed verification harness under `harness/`:

- `harness/dut_wrapper.sv` wraps the DUT and binds the APB and SPI interfaces.
- `harness/apb_if.sv` defines the APB interface.
- `harness/spi_if.sv` defines the SPI master/slave interface.
- `harness/Makefile.template` defines the required targets.
- `harness/grading_interface.md` is the grading contract and must be followed exactly.

This harness is fixed: the team must not modify it. The DUT is provided as golden RTL in `golden_rtl/` and the grader will replace it with buggy RTL during evaluation.

## 2. Are the protocols RTL designed or not?

The protocols are already designed in RTL by the project authors. Your team is not designing the SPI or APB RTL.

- `golden_rtl/spi_master.sv` is the top-level DUT.
- `golden_rtl/apb_regfile.sv` contains the APB register file, FIFOs, interrupts, and APB interface behavior.
- `golden_rtl/spi_core.sv` contains the SPI shift engine, clock generation, MOSI/MISO logic, and SS control.

Your job is to build the verification environment around this RTL, not to change or create the RTL.

## 3. Two-week execution plan

### Week 1: Foundation and functional coverage

**Day 1**
- Read `docs/SPI_Master_Spec.pdf` fully and map spec IDs to required tests.
- Read `harness/grading_interface.md` for the exact file/Makefile/log contract.
- Confirm the submission directory layout and create the skeleton folders:
  - `tb/`
  - `env/`
  - `tests/`
  - `sequences/`
  - `assertions/`
  - `docs/`

**Day 2**
- Copy the `harness/examples/sv_only/` scaffold if doing SystemVerilog-only, or start UVM scaffold if going optional UVM.
- Build the testbench top that instantiates `dut_wrapper` and binds the interfaces.
- Create a `Makefile` from `harness/Makefile.template` and verify `make compile`.

**Day 3**
- Implement APB driver and APB model.
- Implement a basic SPI slave model capable of normal RX/TX and loopback.
- Create a simple reference model for APB register writes and SPI transaction prediction.

**Day 4**
- Implement `reg_access_test` and `sanity_test`.
- Run golden RTL regression for these tests and verify log contract output.
- Add scoreboard checks for APB read/write consistency.

**Day 5**
- Implement the first set of SVA assertions in `assertions/`.
- Add functional coverage points for APB accesses and SPI mode combinations.
- Create `mode_coverage_test` and `width_coverage_test`.

### Week 2: Bug catching, robustness, and reports

**Day 6**
- Implement `fifo_stress_test` and `interrupt_test`.
- Add reference model checks for FIFO full/empty and IRQ behavior.
- Add assertions covering FIFO and interrupt invariants.

**Day 7**
- Implement `clk_div_corner_test` and `delay_transfer_test`.
- Add coverage for clock-div and delay options.

**Day 8**
- Implement `loopback_test` and `error_injection_test`.
- Add assertions for illegal access, reserved register behavior, and FIFO error conditions.

**Day 9**
- Run full regression on golden RTL with a small seed list.
- Measure coverage and fix holes until the environment reaches `>= 85%` functional coverage.
- Confirm `coverage_report.txt` generation with `make cov`.

**Day 10**
- Stabilize logs and naming conventions.
- Add final report skeleton and test plan skeleton in `docs/`.
- Gather evidence of coverage, bug catches, and assertions.

**Day 11-12**
- Polish all tests, review all code, and make sure `make regress` stays under the 10000-run cap.
- If doing UVM, integrate UVM bonus items and validate `make run_bonus`.

**Day 13-14**
- Generate final deliverables:
  - `docs/test_plan.pdf`
  - `docs/final_report.pdf`
  - `docs/coverage_report.pdf`
- Perform final regression and packaging.
- Ensure the zip archive layout matches the grading contract.

## 4. Suggested directory structure

```
<name>_<id>/
  Makefile
  README.md
  tb/
    tb_top.sv
  env/
    spi_env.sv
    spi_agent.sv
    apb_driver.sv
    spi_driver.sv
    spi_monitor.sv
    spi_scoreboard.sv
    spi_cov_collector.sv
    spi_ref_model.sv
    spi_reg_block.sv      # optional if using UVM RAL
  tests/
    sanity_test.sv
    reg_access_test.sv
    mode_coverage_test.sv
    width_coverage_test.sv
    fifo_stress_test.sv
    interrupt_test.sv
    clk_div_corner_test.sv
    loopback_test.sv
    delay_transfer_test.sv
    error_injection_test.sv
    ral_hw_reset_test.sv  # if UVM RAL is attempted
  sequences/
    reg_access_seq.sv
    mode_coverage_seq.sv
    width_coverage_seq.sv
    fifo_stress_seq.sv
    interrupt_seq.sv
    loopback_seq.sv
    delay_transfer_seq.sv
    error_injection_seq.sv
  assertions/
    spi_assertions.sv
  docs/
    test_plan.pdf
    final_report.pdf
    coverage_report.pdf
```

## 5. Suggested class architecture for UVM

If you choose UVM, the clean architecture should look like this:

- `env/spi_env.sv`
  - extends `uvm_env`
  - creates APB and SPI agents
  - connects scoreboard and coverage collector

- `env/spi_agent.sv`
  - extends `uvm_agent`
  - contains `spi_driver`, `spi_monitor`, and `sequencer`

- `env/apb_driver.sv`
  - extends `uvm_driver` for APB transactions
  - sends APB reads/writes to DUT

- `env/spi_driver.sv`
  - extends `uvm_driver` for SPI transfers and MISO handling

- `env/spi_monitor.sv`
  - extends `uvm_monitor`
  - observes APB and SPI signals
  - publishes transactions on analysis ports

- `env/spi_scoreboard.sv`
  - extends `uvm_scoreboard`
  - compares predicted responses vs DUT outputs
  - reports `[SCOREBOARD_ERROR]`

- `env/spi_cov_collector.sv`
  - extends `uvm_subscriber` or `uvm_analysis_imp`
  - collects functional coverage from monitored transactions

- `env/spi_ref_model.sv`
  - contains a spec-based model of APB register behavior and SPI protocol outcomes

- `env/spi_reg_block.sv` (optional)
  - extends `uvm_reg_block`
  - implements the register map for RAL bonus

- `tests/` classes
  - one `uvm_test` per major regression scenario
  - `ral_hw_reset_test` for RAL bonus

- `sequences/`
  - one sequence per test scenario, with constrained-random stimulus

- `assertions/spi_assertions.sv`
  - SVA that binds to the DUT or interface
  - must include at least 5 assertions

## 6. UVM estimate and feasibility

### How long would UVM take?

- If the team uses SV-only, the baseline completion time is typically 2 weeks for a strong student team.
- If the team adds UVM on top, plan for an extra 2–5 days to implement the UVM framework and validate structural bonus requirements.
- If the team also attempts UVM RAL, add another 2–4 days for the register model and backdoor paths.

### Can only one person do UVM?

Yes, one experienced person can own the UVM implementation, but it is not ideal for a team of 7.

- One person can lead the UVM framework and integrator work.
- Others should contribute the reference model, sequences, coverage, assertions, and documentation.
- UVM is easiest when the team splits tasks across components:
  - driver/agent, sequences/tests, scoreboard/ref-model, coverage/assertions, regression/package.

If only one person is assigned UVM, make sure at least two others review the design and help test the environment.
