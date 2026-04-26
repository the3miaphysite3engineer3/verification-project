# UVM Notes for the SPI Master Project

## UVM as an optional enhancement

The project accepts both **SystemVerilog-only** and **UVM** verification approaches.

- UVM is optional and earns bonus points if implemented correctly.
- UVM RAL is a further optional bonus if the register abstraction layer is implemented.
- The grading contract is the same for both approaches: the same test names, log format, and coverage goals.

## How long UVM would take?

- For a team already familiar with UVM, expect about **3–5 days** to build a minimal framework.
- For a team new to UVM, expect **5–8 days** plus extra time to stabilize.
- Adding RAL is another **2–4 days** if the team already has the UVM framework.

## Can only one person do UVM?

Yes, one person can take ownership of the UVM implementation, but this is best when:

- the person has prior UVM experience,
- the rest of the team still builds stimulus, coverage, and reports,
- the team reviews UVM files and validates test results together.

### Practical recommendation

- Let one strong member lead `env/` and UVM integration.
- Let others own sequences, assertions, coverage, documentation, and regression.
- Avoid isolating the entire project to a single person; verification is easier when the team shares test scenarios and validation.

## Key UVM architecture elements

- `tb/tb_top.sv` should import `uvm_pkg::*` and call `run_test()`.
- `env/` should contain `uvm_env`, agents, driver, monitor, scoreboard, and collector.
- `tests/` should contain named `uvm_test` classes for each required regression scenario.
- `sequences/` should capture constrained-random stimulus per major test.
- `assertions/` should provide SVA coverage and must include at least 5 assertions.
- `make run_bonus` should execute `ral_hw_reset_test` if RAL is attempted.
