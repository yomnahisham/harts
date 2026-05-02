# Host protocol: UART, APB, and scheduler commands

The scheduler command set is defined as 32-bit words consumed by `rtl/control_unit.v`. On the current silicon macro, those words reach the control unit through:

1. `uart_apb_master` — serial byte protocol (sync, READ/WRITE, address, data) documented in [`../vendor/uart_apb_master/README.md`](../vendor/uart_apb_master/README.md).
2. `harts_apb_slave` — zero-wait-state APB3 slave with a small register map.

The bit layout of opcodes and parameters is the same as in the older SPI-only documentation; only the transport changed from SPI bit-serial to APB register writes/reads behind the UART bridge.

## APB register map (`harts_apb_slave`)

All offsets are byte addresses; APB words are 32-bit, word-aligned (`PADDR[1:0] == 00`). Upper address bits `PADDR[31:8]` must be zero. Undefined offsets assert `PSLVERR` on the access phase.

| Offset | Name | R/W | Function |
|--------|------|-----|------------|
| `0x00` | CMD_W1 | W | Latches `PWDATA` as `cmd_word`; next cycle `cmd_valid` pulses to the control unit. If the opcode needs a second word, hardware sets `pending_word2` (visible in STATUS). |
| `0x04` | CMD_W2 | W | Latches second word; `cmd_word2_valid` pulses next cycle. |
| `0x08` | RSP | R | Returns `rsp_word` from the control unit. |
| `0x0C` | STATUS | R | `{30'd0, pending_word2, ~irq_n}` — bit 0 is high when scheduler IRQ is active (active-low pin). |
| `0x10` | IRQ_REASON | R | `{24'd0, irq_reason[7:0]}`. |

`PREADY` is tied high (fixed one-cycle data phase from the slave’s perspective for mapped registers).

Typical host sequence:

- Single-word command: UART WRITE32 to `CMD_W1` with the full command word; optionally poll STATUS or wait for IRQ; UART READ32 of RSP if a response is defined for that opcode.
- Two-word command (CREATE, MODIFY, SLEEP long, …): WRITE32 `CMD_W1`, then WRITE32 `CMD_W2`; then read RSP as needed. Do not send word 2 before word 1 is accepted; use STATUS `pending_word2` if you need to confirm the first word requested a follow-up.

UART bridge addressing: the scheduler slave is the only APB target wired in `hw_scheduler_top`; use the base address expected by your bridge instance (often slave 0 with offset 0 in the 8 KB slot—see vendor README for `PADDR` construction from the 32-bit UART address field).

## Command word format (32 bits)

```
┌─────────────────────────────────────────────────────────────────┐
│ Opcode │  Task ID │ Param A  │ Param B  │ Param C  │
│ [31:28]│ [27:24]  │ [23:16]  │ [15:8]   │ [7:0]    │
├─────────────────────────────────────────────────────────────────┤
│  4 bits │  4 bits  │  8 bits  │  8 bits  │  8 bits  │
└─────────────────────────────────────────────────────────────────┘
```

### Multi-word commands

Opcodes CREATE (0x4), MODIFY (0x6), and SLEEP long (0x7) require two 32-bit words: first CMD_W1, then CMD_W2. The APB slave enforces the one-cycle staging described in `rtl/harts_apb_slave.v` so the control unit never sees a stale `cmd_word` on `cmd_valid`.

## Opcode map

| Hex | Mnemonic | Purpose | Notes |
|-----|----------|---------|--------|
| 0x0 | NOP | No-op | |
| 0x1 | CONFIGURE | Mode, tick divider, flags | See below |
| 0x2 | RUN | Mark task running | Task ID |
| 0x3 | STOP | Mark task stopped | Task ID |
| 0x4 | CREATE | New task | Two words |
| 0x5 | DELETE | Remove task | Task ID |
| 0x6 | MODIFY | Update task | Two words |
| 0x7 | SLEEP_LONG | Sleep with 32-bit tick count | Two words |
| 0x8 | SLEEP_SHORT | Sleep with 24-bit count in word 1 | One word |
| 0x9 | YIELD | Yield | Task ID |
| 0xA | SUSPEND | Suspend | Task ID |
| 0xB | RESUME | Resume | Task ID |
| 0xC | ACTIVATE | Ready a suspended task | Task ID |
| 0xD | QUERY | Status query | Response in RSP |
| 0xE | SCAN_MODE | Scan / debug | |
| 0xF | RESET | Full reset | Param A must be safety key `0xAD` |

## CONFIGURE (0x1)

Param A [1:0] — scheduling mode: `00` priority, `01` RM, `10` EDF, `11` LLF.

Param B — tick divider: divides the macro clock to produce scheduler ticks. Example: macro at 40 MHz (25 ns period in the shipped OpenLane config) with divider 100 → 400 kHz tick rate. Scale to your synthesized clock.

Param C — flags (preemption, deadline IRQ, scan, LLF threshold, etc.); see `rtl/control_unit.v` for which bits are implemented.

## QUERY (0xD)

`Param A` is `cmd_word[23:16]` and selects what `rsp_word` contains for QUERY (see `rtl/control_unit.v`):

| Param A | `rsp_word` contents |
|---------|---------------------|
| `0x00` | Task status bits for the task ID in `cmd_word[27:24]` (`tt_rd_status`, padded). |
| `0x01` | Current running task ID (`current_task`). |
| `0x02` | Priority queue depth (`pq_depth`). |
| `0x03` | Sleep queue depth (`sq_depth`). |
| `0x04` | `0` in current RTL (reserved). |
| `0x05` | `irq_reason` (low 8 bits). |
| `0x06` | Global `tick_count`. |
| `0x07` | `{sched_mode, flags_reg}` (padded). |

Host flow: WRITE32 `CMD_W1` with QUERY encoding; READ32 `RSP` for the result.

## IRQ reasons

When `irq_n` is low, read IRQ_REASON or QUERY with param `0x05`. Values driven in `rtl/control_unit.v` today:

| Code | Source |
|------|--------|
| `0x01` | Preemption: higher-key ready head vs. running task (with preemption enabled in flags). |
| `0x03` | Deadline miss (tick crossed absolute deadline while task running). |
| `0x04` | Task woke from sleep queue into ready path (may preempt). |
| `0x05` | External IRQ treated as fast (`fast_mask` bit for asserted line). |
| `0x06` | External IRQ treated as slow. |

Other codes may appear in older documentation; always treat `control_unit.v` as authoritative.

## CREATE / MODIFY / SLEEP_LONG word layouts

Same bit packing as before; word 1 carries opcode, task ID, and packed fields; word 2 carries period/WCET or 32-bit sleep count as applicable. See `rtl/control_unit.v` for exact field extraction.

### RESET (0xF)

```
Opcode [31:28] = 0xF; Param A [23:16] = 0xAD (safety key); remaining fields per RTL.
```

If the key is wrong, reset is ignored (see control unit behavior).

## Legacy SPI documentation

Older revisions exposed the same `cmd_word` / `rsp_word` interface through `rtl/legacy/spi_slave_if.v` (SPI mode 0, 32-bit shifts). That module is not part of `hw_scheduler_top` today. For historical SPI timing diagrams, retrieve an old revision of this file from git history under `docs/spi_protocol.md`.
