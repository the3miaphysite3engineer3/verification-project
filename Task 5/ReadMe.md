###### **The Bind Statement**

To integrate this into your environment without modifying the RTL, place this bind statement in your tb\_top.sv. It maps the top-level APB/SPI signals directly and uses hierarchical paths (guaranteed by the spec contract) to access the internal registers and state.



""

bind dut\_wrapper.u\_dut spi\_master\_sva u\_sva (

&#x20;   .PCLK(PCLK),

&#x20;   .PRESETn(PRESETn),

&#x20;   .PSEL(PSEL),

&#x20;   .PENABLE(PENABLE),

&#x20;   .PWRITE(PWRITE),

&#x20;   .PADDR(PADDR),

&#x20;   .PWDATA(PWDATA),

&#x20;   .SCLK(SCLK),

&#x20;   .MOSI(MOSI),

&#x20;   .SS\_n(SS\_n),

&#x20;   .IRQ(IRQ),

&#x20;   .BUSY(u\_core.BUSY),

&#x20;   .CPOL(u\_regfile.CTRL\[3]),

&#x20;   .CPHA(u\_regfile.CTRL\[2]),

&#x20;   .INT\_STAT(u\_regfile.INT\_STAT),

&#x20;   .INT\_EN(u\_regfile.INT\_EN),

&#x20;   .TX\_FULL(u\_regfile.STATUS\[1]),

&#x20;   .RX\_FULL(u\_regfile.STATUS\[3]),

&#x20;   .TX\_OVF(u\_regfile.STATUS\[5]),

&#x20;   .RX\_OVF(u\_regfile.STATUS\[6])

);



""



###### **Logic and Architectural Breakdown**

**APB Protocol Consistency:**



**p\_apb\_psel\_2cycles:** Validates that the APB SETUP phase natively transitions into an ACCESS phase by ensuring PSEL stays high for at least two consecutive clock cycles.



**p\_apb\_penable\_psel:** Ensures PENABLE never acts independently; it is strictly bounded by an active PSEL.



**p\_apb\_stable\_ctrl:** A critical bus rule. It dictates that during the transition from SETUP to ACCESS, the address, control, and data signals must not flip.



**SPI Timing and Integrity:**



**p\_spi\_sclk\_idle:** Binds the serial clock directly to the CPOL configuration whenever the shift engine is inactive (BUSY = 0).



**p\_spi\_mosi\_stable:** Dynamically constructs the sample edge (is\_sample\_edge) based on the active CPHA and CPOL combination. It uses $stable and cycle delays (##1) to guarantee MOSI doesn't transition one cycle before or after the target edge, fulfilling the wire-stability requirement.



**p\_spi\_ssn\_held:** Asserts that while BUSY is maintained, the slave select vector cannot be altered.



**FIFO Overflow Protection:**



**p\_fifo\_tx\_ovf:** Detects an active APB write targeting the TX\_DATA register offset (0x08). If TX\_FULL is high during this push, it mandates that the TX\_OVF flag raises on the immediate next clock.



**p\_fifo\_rx\_ovf:** Uses the falling edge of BUSY to identify the completion of a hardware SPI transfer. If the RX FIFO is full at this exact moment, it enforces the hardware to flag RX\_OVF.



**Interrupt Combinational Logic:**



**p\_irq\_comb:** Continuously evaluates the interrupt output against the masked status registers to ensure zero-latency assertion.

