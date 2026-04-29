# Hardware Scheduler Architecture

## Objective

Design an open-source hardware scheduling coprocessor for the SKY130 process node. The coprocessor offloads real-time scheduling decisions from the host CPU, determining task execution order, timing, and preemption in dedicated silicon.

## Design Philosophy

- **Hardware acceleration**: Move scheduling logic into hardware for deterministic, predictable behavior
- **Simple host interface**: Minimal CPU overhead via SPI command/response protocol
- **Modularity**: Clean separation of concerns across specialized modules
- **Verifiability**: Each component thoroughly tested before integration

## Top-Level Modules

| Module | Purpose |
|--------|----------|
| **Control Unit** | Orchestrates scheduling decisions and command arbitration |
| **Priority Queue** | Maintains sorted ready task queue |
| **Sleep Queue** | Manages timer-based task wake-up events |
| **Task Table** | Stores task descriptors and runtime state |
| **Timer** | Generates periodic tick events for timekeeping |
| **Interrupt Controller** | Signals host CPU via active-low IRQ |
| **SPI Slave Interface** | Handles host command/response transactions |
| **Scan Chain** | Provides state visibility for debugging and bring-up |

## Data Flow

Typical task scheduling cycle:

1. **Command Phase**: Host sends SPI command (create, modify, run, stop, etc.)
2. **Decode**: SPI interface decodes 32-bit command word
3. **Execution**: Control unit updates task table and queue state based on command
4. **Tick Generation**: Timer produces periodic clock ticks
5. **Sleep Management**: Sleep queue decrements counters per tick, wakes expired tasks to ready queue
6. **Queue Maintenance**: Priority queue keeps ready tasks sorted by scheduling key
7. **Decision**: Control unit evaluates readiness and determines if preemption needed
8. **IRQ**: If preemption required, interrupt controller asserts IRQ to host
9. **Response**: Host performs software context switch and reads next task ID via query command

## Datapath Architecture

```
Host CPU (ESP32)
      ↓
   SPI Bus
      ↓
  SPI Slave IF → Command Decoder
      ↓
  Control Unit (Arbitration)
      ├→ Task Table (Read/Write)
      ├→ Priority Queue (Enqueue/Dequeue)
      ├→ Sleep Queue (Decrement)
      └→ Interrupt Controller → IRQ_N
      ↑
   Timer (Periodic Ticks)
```

## Scheduling Modes

The scheduler supports multiple real-time scheduling algorithms, selectable via the CONFIGURE command:

| Mode | Key | Use Case |
|------|-----|----------|
| **Priority** | Static task priority | General-purpose, custom priorities |
| **RM (Rate Monotonic)** | Inverted period (1/T) | Periodic tasks with known periods |
| **EDF (Earliest Deadline First)** | Inverted absolute deadline | Deadline-driven workloads |
| **LLF (Least Laxity First)** | Inverted laxity (deadline - WCET) | Compile-time optional; tight deadlines |

**Scheduling Key Calculation**:
- Higher key value = higher priority (dequeued first)
- For RM: key = MAX_PERIOD - period
- For EDF: key = MAX_DEADLINE - abs_deadline
- Queue maintains stable ordering (insertion order for equal keys)

## Task Descriptor Format

Each task is described by a fixed-size descriptor stored in the Task Table, indexed by task ID:

| Field | Bits | Purpose |
|-------|------|----------|
| priority | 4 | Static priority (0-15, higher = more important) |
| period | 16 | Periodic task interval (ticks) |
| deadline | 16 | Relative deadline from activation |
| wcet | 16 | Worst-case execution time (ticks) |
| remaining_wcet | 16 | Time budget remaining in current invocation |
| task_type | 1 | 0=aperiodic, 1=periodic |
| preemptable | 1 | 0=non-preemptable, 1=preemptable |
| status | 3 | Current task state (see below) |
| abs_deadline | 16 | Absolute deadline for current invocation |

### Task Status Encoding

| Code | State | Meaning |
|------|-------|----------|
| 000 | **Deleted** | Task does not exist (recycled slot) |
| 001 | **Suspended** | Created but not eligible to run |
| 010 | **Ready** | Eligible to run, queued in priority queue |
| 011 | **Running** | Currently executing on host CPU |
| 100 | **Sleeping** | Waiting for timer expiration in sleep queue |

## Queue Semantics

### Priority Queue

Maintains ready tasks sorted by scheduling key with O(1) dequeue and O(log N) enqueue:

- **One enqueue request per cycle**: Ordered insertion maintains sorted invariant
- **One dequeue request per cycle**: Always removes highest-key (most-ready) task
- **Stable ordering**: For equal keys, insertion order is preserved
- **Lazy delete**: Tasks marked for deletion remain in queue but are skipped during dequeue (efficiency over immediate removal)
- **Capacity**: Supports up to 16 concurrent ready tasks

### Sleep Queue

Manages timer-based wake-up events with precise tick-based expiration:

- **Entry format**: Task ID + countdown counter (ticks)
- **Tick decrement**: All active entries decrement by 1 each cycle
- **Wake-up**: When counter reaches zero, task moves from Sleep Queue to Priority Queue (Ready state)
- **Multiple wake-ups**: Multiple tasks can wake in same cycle with deterministic ordering
- **Capacity**: Supports up to 8 concurrent sleeping tasks

## Control Unit Behavior

The Control Unit is the central arbitration point, coordinating three concurrent data flows:

| Flow | Purpose | Typical Duration |
|------|---------|------------------|
| **Command Execution** | Process SPI commands (create, modify, run, stop) | 1-2 cycles |
| **Tick Service** | Decrement sleep queue, advance timers | 1 cycle |
| **Preemption Check** | Evaluate if task switch needed | 1 cycle |

### Arbitration Priority

1. **Reset** - Highest priority; clears all state
2. **Tick Pending** - Advance timers and sleep counters
3. **Command In Progress** - Execute queued SPI command
4. **Preemption Check** - Determine if context switch needed

This ordering ensures timekeeping is never delayed by command processing.

## Host Responsibilities

The host CPU must:

1. **Initialize**: Send CONFIGURE command to set scheduling mode and tick rate
2. **Manage Tasks**: Create, modify, suspend, resume, and delete tasks via SPI commands
3. **Handle IRQ**: React to scheduler IRQ by reading IRQ reason via QUERY command
4. **Context Switch**: Perform software context switch based on scheduler decision
5. **Acknowledge**: Send RUN/STOP commands to scheduler after context switch

## Reset Guarantees

When RESET command is issued (opcode 0xF with safety key 0xAD):

✓ All queues invalidated (no pending tasks)  
✓ Task table cleared (all tasks → Deleted state)  
✓ IRQ deasserted (no pending interrupt)  
✓ Mode reset to Priority scheduling  
✓ Tick counter reset to zero  
✓ All flags cleared  

