# Hardware Scheduler Architecture

## Objective

Open-source hardware scheduling coprocessor for the SkyWater SKY130 node. The block offloads real-time scheduling decisions from a host processor: it tracks task state, orders ready work, manages timed sleep, and signals the host when a scheduling event needs software attention (for example preemption).

## Design Philosophy

- Hardware acceleration: Scheduling and timekeeping in deterministic silicon instead of a variable-cost software loop.
- Simple host interface: A UART link into an AMBA APB3 register file; the host issues 32-bit writes for commands and reads status and responses without a dedicated parallel bus.
- Modularity: Control path, queues, task storage, timer, and interrupt logic are separate Verilog modules.
- Verifiability: Block-level and full-chip testbenches under `verif/tb_verilog/`.

## Top-Level Macro (`hw_scheduler_top`)

| Block | Role |
|--------|------|
| `uart_apb_master` (vendor) | Decodes UART byte frames into single APB read/write transactions. |
| `harts_apb_slave` | APB3 slave: `CMD_W1` / `CMD_W2` writes pulse `cmd_valid` / `cmd_word2_valid` into the control unit; `RSP`, `STATUS`, `IRQ_REASON` reads. |
| Control unit | Command decode, scheduling policy, queue and task-table side effects, preemption. |
| Priority queue | Ready tasks sorted by scheduling key (depth 6 in the current top-level instance). |
| Sleep queue | Countdown-based sleep entries (depth 16). |
| Task table | Up to 16 task descriptors (IDs 0–15). |
| Timer | Divides the macro clock to produce scheduler tick pulses. |
| Interrupt controller | Masks, external IRQs, and `irq_n` / `irq_reason` to the host. |
| Scan chain | Optional scan for bring-up and debug. |

Legacy RTL for an SPI front end lives under `rtl/legacy/spi_slave_if.v` and is not instantiated in the current OpenLane top.

## Data Flow

Typical scheduling cycle:

1. Host command: Host sends a 32-bit command word (and second word if required) via UART → APB writes to `harts_apb_slave` (see `host_protocol.md`).
2. Decode: APB slave asserts `cmd_valid` / `cmd_word2_valid` to the control unit with the registered words.
3. Execution: Control unit updates the task table and priority or sleep queues per opcode.
4. Ticks: Timer generates periodic pulses; sleep entries decrement and can wake tasks into the ready queue.
5. Ordering: Priority queue holds ready tasks ordered by the active policy’s key.
6. Preemption: Control unit may assert interrupt when the host should run a different task.
7. Response: Host reads `RSP` over APB (UART read transaction) for the control unit’s `rsp_word`.

## Datapath (conceptual)

```
Host (any MCU / PC UART)
      │
      ▼  8N1 serial, bridge framing (see vendor/uart_apb_master/README.md)
uart_apb_master
      │
      ▼  APB3
harts_apb_slave  ──►  cmd_valid / cmd_word / cmd_word2_valid
      ▲                    │
      │                    ▼
      │              control_unit
      │                    ├──► task_table
      │                    ├──► priority_queue
      │                    ├──► sleep_queue
      │                    └──► interrupt_ctrl ──► irq_n
      │                    ▲
      └── rsp_word ────────┘
timer ──► tick_pulse ──────────────────────────────┘
```

## Scheduling Modes

Selectable via the CONFIGURE command (`sched_mode` in RTL):

| Mode | Key idea | Typical use |
|------|-----------|--------------|
| Priority | Static per-task priority | General-purpose fixed ordering |
| RM | Rate monotonic (period-based key) | Periodic implicit deadlines |
| EDF | Earliest-deadline-first | Explicit deadlines |
| LLF | Least laxity first | Tight timing; uses remaining WCET and deadline |

Key ordering: Higher scheduling key = served first from the priority queue. Exact key computation is implemented in `rtl/control_unit.v` (for example inverted period or deadline fields for RM/EDF).

## Task Descriptor (task table)

Each task ID (4 bits → 16 tasks) has a descriptor; fields include priority, period, deadline, WCET, remaining WCET, type (periodic vs aperiodic), preemptable flag, status, and absolute deadline. See `rtl/task_table.v` and the control unit for exact bit layouts.

### Task status (conceptual)

| Code | State | Meaning |
|------|--------|---------|
| 000 | Deleted | Slot unused |
| 001 | Suspended | Not eligible to run |
| 010 | Ready | In or eligible for priority queue |
| 011 | Running | Host is executing this task |
| 100 | Sleeping | In sleep queue until counter expires |

## Queue Semantics

### Priority queue

- Sorted by scheduling key; one dequeue per cycle when requested.
- Capacity: parameterized; `hw_scheduler_top` sets depth 6 (not the full 16 task IDs—design trade-off for area/timing).

### Sleep queue

- Entries: task ID + tick counter; on each tick, counters advance toward wake.
- Capacity: 16 entries (`sleep_queue` default `DEPTH`).

## Control unit arbitration

Rough priority among reset, tick processing, command execution, and preemption checks is documented in the FSM comments in `rtl/control_unit.v`. Timekeeping and command paths are structured so ticks are not indefinitely starved by command traffic.

## Host responsibilities

1. Configure: Set scheduling mode, tick divider, and flags via CONFIGURE.
2. Tasks: CREATE / MODIFY / DELETE / ACTIVATE / SUSPEND / RESUME as needed.
3. Run / stop: RUN and STOP to reflect which task the CPU is executing.
4. IRQ: When `irq_n` is asserted (active low), read `IRQ_REASON` via APB and handle (see `host_protocol.md`).
5. Queries: Use QUERY opcodes for depth, running task, mode, etc.; response appears in `RSP` after the command is processed.

## Reset

The RESET opcode (with the required safety key in the command word) clears queues and task state, deasserts IRQ, and returns scheduling mode to priority; see `host_protocol.md` and `rtl/control_unit.v`.
