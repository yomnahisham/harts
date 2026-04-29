# SPI Protocol Specification

This document describes the host-to-scheduler communication protocol used over SPI.

## Physical Interface

| Signal | Direction | Encoding | Purpose |
|--------|-----------|----------|----------|
| **SCLK** | Input | Clock | SPI clock, mode 0 (CPOL=0, CPHA=0) |
| **CS_N** | Input | Active Low | Chip select (frame delimiter) |
| **MOSI** | Input | Serial | Host → Scheduler data |
| **MISO** | Output | Serial | Scheduler → Host response |
| **IRQ_N** | Output | Active Low | Interrupt signal (context switch event) |

**Protocol Parameters**:
- Mode: SPI Mode 0 (CPOL=0, CPHA=0)
- Word width: 32 bits per transaction
- Bit order: MSB first
- Max frequency: 10 MHz (typ.), check synthesis SDF

## Command Framing

### Word Format (32 bits)

```
┌─────────────────────────────────────────────────────────────────┐
│ Opcode │  Task ID │ Param A  │ Param B  │ Param C  │
│ [31:28]│ [27:24]  │ [23:16]  │ [15:8]   │ [7:0]    │
├─────────────────────────────────────────────────────────────────┤
│  4 bits │  4 bits  │  8 bits  │  8 bits  │  8 bits  │
└─────────────────────────────────────────────────────────────────┘
```

### Multi-Word Commands

Some commands (CREATE, MODIFY, SLEEP_LONG) require two 32-bit words:
- **Word 1**: Opcode, task ID, primary parameters
- **Word 2**: Extended parameters (period, WCET, etc.)

Host initiates multi-word transfer by keeping CS_N low for both transfers.

## Opcode Map

| Hex | Mnemonic | Purpose | Parameters |
|-----|----------|---------|------------|
| 0x0 | NOP | No-op | None |
| 0x1 | CONFIGURE | Set mode, tick rate, flags | See CONFIGURE section |
| 0x2 | RUN | Mark task running | Task ID |
| 0x3 | STOP | Mark task stopped | Task ID |
| 0x4 | CREATE | Create new task | Word 1: Task ID, priority, type; Word 2: period, WCET |
| 0x5 | DELETE | Remove task | Task ID |
| 0x6 | MODIFY | Update task parameters | Word 1: Task ID; Word 2: new period, WCET |
| 0x7 | SLEEP_LONG | Sleep task (long form) | Word 1: Task ID; Word 2: 32-bit tick count |
| 0x8 | SLEEP_SHORT | Sleep task (short form) | Task ID, 24-bit tick count in params |
| 0x9 | YIELD | Task yields control | Task ID |
| 0xA | SUSPEND | Suspend task | Task ID |
| 0xB | RESUME | Resume suspended task | Task ID |
| 0xC | ACTIVATE | Make suspended task ready | Task ID |
| 0xD | QUERY | Query status register | See QUERY section |
| 0xE | SCAN_MODE | Enter scan chain mode | Control flags |
| 0xF | RESET | Reset scheduler to clean state | Requires safety key 0xAD |

## CONFIGURE Command Details

Opcode: 0x1

**Param A [1:0] - Scheduling Mode**:
| Code | Mode | |
|------|------|---|
| 00 | Priority | Static priority-based |
| 01 | RM | Rate Monotonic |
| 10 | EDF | Earliest Deadline First |
| 11 | LLF | Least Laxity First (optional) |

**Param B - Tick Divider**:
Divides input clock to create scheduler ticks. Typical value: 100 (1μs ticks @ 100MHz clock)

**Param C - Configuration Flags**:
```
Bit 7: Preemption Enable (1 = allow task preemption)
Bit 6: Deadline IRQ Enable (1 = assert IRQ on deadline miss)
Bit 5: Scan Enable (1 = enable scan chain mode)
Bit 4: LLF Threshold Enable (1 = enable laxity threshold feature)
Bits 3-0: Reserved (must be 0)
```

## QUERY Command Details

Opcode: 0xD. Returns scheduler status register selected by Param A.

| Param A | Status Register | Returns |
|---------|-----------------|----------|
| 0x00 | Task Status | Current status of task in Param B [3:0] |
| 0x01 | Running Task ID | ID of currently executing task |
| 0x02 | PQ Depth | Number of tasks in Priority Queue |
| 0x03 | SQ Depth | Number of tasks in Sleep Queue |
| 0x04 | Deadline Miss Bitmask | Low 32 bits of deadline miss error bitmask |
| 0x05 | IRQ Reason | Reason for last IRQ assertion (see IRQ Reasons) |
| 0x06 | Tick Counter | Current global tick counter value |
| 0x07 | Mode & Flags | Scheduling mode and configuration flags |

Response in MISO register during next transaction.

## IRQ Reasons

When IRQ_N is asserted, query the IRQ Reason register (0x05) to determine cause:

| Code | Event | Action |
|------|-------|--------|
| 0x01 | **Preemption Needed** | Higher-priority task ready; perform context switch |
| 0x02 | **Yield Requested** | Running task yielded; dispatch next ready task |
| 0x03 | **Deadline Miss** | Task missed deadline; handle deadline exception |
| 0x04 | **Wakeup May Preempt** | Task woke from sleep with higher priority |
| 0x05 | **Fast External IRQ** | External fast interrupt asserted |
| 0x06 | **Slow External IRQ** | External slow interrupt asserted |

## Transaction Model

Each SPI transaction follows this sequence:

1. **Assert**: Host lowers CS_N (chip select)
2. **Transfer**: Host clocks 32 bits on MOSI while reading 32 bits from MISO
   - MOSI carries command word
   - MISO returns response/status from previous transaction
3. **Multi-word**: For commands requiring 2 words, keep CS_N low and repeat step 2
4. **Deassert**: Host raises CS_N (frame boundary)

**Timing Example (32-bit transaction)**:
```
CS_N    ───┐                                    ┌───
           └────────────────────────────────────┘
           
SCLK    ────┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬────
           
MOSI    ────D31─D30─...─D1─D0──────────────────────
           
MISO    ────────R31─R30─...─R1─R0───────────────────
```

## CREATE Command Format

Opcode: 0x4. Requires two 32-bit words.

**Word 1**:
```
┌──────────┬──────────┬────────┬─┬─┬──────────────────┐
│ Opcode   │ Task ID  │Priority│T│P│    Deadline      │
│ [31:28]  │ [27:24]  │ [23:20]│T│E│    [15:0]        │
│   0x4    │ 0-15     │  0-15  │1│1│    0-65535       │
└──────────┴──────────┴────────┴─┴─┴──────────────────┘
           4 bits    4 bits     4 bits 1 1    16 bits

Bit 19: Task Type (T) - 0=aperiodic, 1=periodic
Bit 18: Preemptable (P) - 0=non-preemptable, 1=preemptable
```

**Word 2**:
```
┌─────────────────────┬─────────────────────┐
│      Period         │       WCET          │
│    [31:16]          │      [15:0]         │
│    0-65535 ticks    │    0-65535 ticks    │
└─────────────────────┴─────────────────────┘
     16 bits              16 bits
```

**Restrictions**:
- Task ID must be unique (0-15)
- Task starts in **Suspended** state
- Use ACTIVATE command to make task ready
- Deadline and period must not be zero for periodic tasks

## MODIFY Command Format

Opcode: 0x6. Same format as CREATE.

**Word 1**: Opcode (0x6), Task ID, new priority, task type, preemptable flag, new deadline  
**Word 2**: New period, new WCET

**Note**: Cannot modify task that is currently Running. Suspend first if needed.

## SLEEP Commands

### SLEEP_LONG (Opcode 0x7)
For arbitrary tick counts > 255:
- **Word 1**: Opcode 0x7, Task ID
- **Word 2**: Full 32-bit tick count
- Task transitions to Sleeping state

### SLEEP_SHORT (Opcode 0x8)
For tick counts ≤ 255 (optimized encoding):
- **Word 1**: Opcode 0x8, Task ID, 24-bit tick count in Param A-C
- Task transitions to Sleeping state

Both forms move task from Ready/Running to Sleep Queue.

## RESET Command Safety

Opcode: 0xF with **Param A = 0xAD** (safety key)

```
┌──────────┬──────────┬──────────┬──────────┬──────────┐
│ Opcode   │Safety Key│   0x00   │   0x00   │   0x00   │
│ [31:28]  │ [27:24]  │ [23:16]  │ [15:8]   │ [7:0]    │
│   0xF    │   0xAD   │   0x00   │   0x00   │   0x00   │
└──────────┴──────────┴──────────┴──────────┴──────────┘
```

**Safety Mechanism**: If Param A ≠ 0xAD, reset is rejected and error flag is set.  
**Effect on rejection**: No state change; error persists until read.
