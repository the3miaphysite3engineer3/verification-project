# SPI Scoreboard Architecture Document

## 1. Executive Summary

The `spi_scoreboard` acts as the definitive source of truth (the "Golden Model") for the SPI Master core verification environment. Instead of reviewing individual code lines, this document provides an abstract overview of how the scoreboard operates, how it models the DUT (Design Under Test), and how team members should interact with it during testing.

The primary goal of the scoreboard is to passively monitor bus traffic, predict what the DUT *should* do, and flag any discrepancies with a `[SCOREBOARD_ERROR]` log.

---

## 2. High-Level Architecture & Data Flow

The scoreboard sits at the backend of the verification environment and receives transaction data via **Mailboxes**. It operates asynchronously across two primary domains:

1. **APB Domain (`apb_mbx`)**: Receives all read and write transactions detected on the APB interface.
2. **SPI Domain (`spi_mbx`)**: Receives all physical serial data shifts detected on the SPI pins (MOSI/MISO).

The scoreboard uses these two streams to maintain a software representation of the DUT and continuously cross-check observed behavior against its internal predictions.

---

## 3. The Golden Reference Model

Internally, the scoreboard maintains a mirror of the DUT's state. This includes:

- **Configuration Registers**: State variables that track the `CTRL`, `CLK_DIV`, `SS_CTRL`, and `DELAY` configuration.
- **Interrupts & Status**: Variables tracking the real-time status of `INT_EN` and `INT_STAT` (including Write-1-to-Clear logic).
- **FIFO Queues**: Two dynamic SystemVerilog queues (`tx_fifo` and `rx_fifo`) that model the 8-deep, 32-bit wide hardware FIFOs.

When the DUT is reset, the scoreboard initializes this internal model to match the hardware's documented reset state (e.g., setting the TX_EMPTY and RX_EMPTY status bits).

---

## 4. Verification Strategy & Checkers

The scoreboard utilizes two parallel processing threads to enforce protocol correctness:

### A. The APB Checker

When the scoreboard receives an **APB Write** transaction:

- It updates the Golden Model. For example, writing to the `TX_DATA` register pushes a new word into the internal `tx_fifo` queue. If the queue is already full, it sets the `TX_OVF` (Transmit Overflow) interrupt bit.

When the scoreboard receives an **APB Read** transaction:

- It intercepts the address being read and calculates what the expected output should be based on its Golden Model.
- For `RX_DATA` reads, it pops the oldest word from the internal `rx_fifo`.
- It then compares the calculated expected data against the actual data returned by the DUT. A mismatch triggers an error.

### B. The SPI Checker

When the scoreboard receives an **SPI Transaction**:

- It assumes the DUT has shifted out a data word over MOSI.
- The scoreboard pops the oldest word from its internal `tx_fifo`.
- It applies the dynamically configured word-width mask (8, 16, or 32 bits based on the `CTRL` register) to both the expected data and the observed MOSI data.
- It compares the two values. A mismatch here means the SPI core transmitted corrupted data or transmitted out of order.
- **Loopback Support**: If the `LOOPBACK` configuration is enabled, the scoreboard automatically routes the transmitted data back into the `rx_fifo` so subsequent APB reads can be verified.

---

## 5. Integration Guide for Team Members

For team members building the testbench or writing test sequences, here is how you interact with the scoreboard:

### For the Environment Integrator (`tb_top` / `env.sv`)

You must instantiate the scoreboard and wire the monitor mailboxes into it:

```systemverilog
// 1. Declare Mailboxes
mailbox #(apb_transaction) apb_mbx = new();
mailbox #(spi_transaction) spi_mbx = new();

// 2. Pass mailboxes into the monitors/agents
apb_agt = new(..., apb_mbx);
spi_agt = new(..., spi_mbx);

// 3. Instantiate and run the scoreboard
scb = new(apb_mbx, spi_mbx);
scb.run();

// 4. Report results at the end of simulation
scb.report();
```

### For the Test Writers (`sequences.sv`)

You do not need to call the scoreboard directly. Just write your APB/SPI sequences naturally!

- If you write data to `TX_DATA` and trigger an SPI transfer, the scoreboard will automatically intercept it and verify the output.
- If you want to test edge cases (like Overflow), intentionally flood the `TX_DATA` register. The scoreboard will automatically update its internal `INT_STAT` and expect the DUT's `STATUS` register to reflect the overflow on the next read.

**Note on Reporting**: The scoreboard tracks a running `error_count`. At the end of the simulation, calling `scb.report()` will print exactly `[TEST_PASSED]` or `[TEST_FAILED]`, adhering strictly to the grading script requirements.
