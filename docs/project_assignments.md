# Team Assignments and Responsibilities

## Assigned tasks

- **Omar Helmy**
  - Own the **scoreboard** design and implementation.
  - Responsibilities:
    - Define scoreboarding checks for APB transactions.
    - Compare DUT SPI output against the reference model.
    - Report `[SCOREBOARD_ERROR]` on mismatches.
    - Validate scoreboard behavior across mode, width, FIFO, delay, and interrupt tests.

- **Kareem Shawki**
  - Own the **5 required assertions**.
  - Responsibilities:
    - Write at least five SystemVerilog assertions in `assertions/`.
    - Bind assertions to the DUT or interfaces.
    - Cover key protocol invariants such as:
      - APB write/read consistency
      - FIFO full/empty safety
      - valid SPI clock/SS timing
      - interrupt/clear-on-write behavior
      - illegal access or reserved register protection

## Suggested team split for 7 members

1. **Testbench / Makefile integrator**
   - Build `tb_top.sv`, Makefile, and run environment validation.
2. **APB driver + reference model**
   - Implement APB stimulus, APB prediction, and regression tests.
3. **SPI driver / slave model**
   - Implement SPI stimulus generation, loopback support, and MISO behavior.
4. **Scoreboard owner**
   - Omar Helmy: implement scoreboarding and bug detection.
5. **Assertion owner**
   - Kareem Shawki: implement SVA assertions and assertion checks.
6. **Coverage / regression owner**
   - Add functional coverage points and maintain `make regress`.
7. **Documentation / reports**
   - Produce `docs/test_plan.pdf`, `docs/final_report.pdf`, and `docs/coverage_report.pdf`.
