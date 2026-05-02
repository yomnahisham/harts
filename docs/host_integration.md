# Host integration notes

This project’s production top (`hw_scheduler_top`) connects the scheduler to a host with:

- `uart_rx` / `uart_tx` — 8N1 UART at a baud rate set by the `UART_DIVISOR` parameter (default chosen for ~115200 baud at the OpenLane 40 MHz macro clock; adjust for your clock).
- `irq_n` — active-low interrupt from the scheduler (polarity and GPIO wiring are host-specific).
- `ext_irq[7:0]` — external event inputs into `interrupt_ctrl`.
- `clk` / `rst_n` — macro clock and asynchronous reset.

## UART → APB

The `uart_apb_master` block parses framed commands on RX and drives a single APB master. Details (sync bytes `0xDE 0xAD`, write `0xA5`, read `0x5A`, lock sequence, timeout) are in:

[`../vendor/uart_apb_master/README.md`](../vendor/uart_apb_master/README.md)

The scheduler’s register file is documented in `host_protocol.md`.

## Software bring-up (outline)

1. Configure the host UART to match 8N1 and the chosen baud rate.
2. After reset, send CONFIGURE so tick rate and scheduling mode match your RTOS or bare-metal model.
3. CREATE tasks, ACTIVATE as needed, then RUN the first task.
4. Install a GPIO or IRQ handler for `irq_n`; on assert, read IRQ_REASON or QUERY and perform context switch, then RUN / STOP as required.

## Simulation reference

`verif/tb_verilog/tb_hw_scheduler_top_final.v` drives the DUT with UART bit-banging and APB-level expectations; it is the best reference for correct framing and ordering.

## Formal / other RTL

`formal/` may contain standalone checks. `rtl/legacy/spi_slave_if.v` is retained for reference only and is not in the current synthesis list (`flow/openlane/config.json`).
