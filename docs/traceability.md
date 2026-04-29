# Requirements Traceability Matrix

This document maps each system requirement to implementation components and verification tests.

## Overview

Requirements derived from:
- HARTS research paper (scheduling algorithm specifications)
- Architecture frozen documents (hardware module definitions)
- SPI protocol specification
- ESP32 integration requirements

Each requirement is traced through:
1. **RTL Modules**: Hardware implementation
2. **Firmware Components**: Host-side code (if applicable)
3. **Tests**: Verification coverage
4. **Status**: Current implementation state

---

## Requirements

### R01: Support Priority, RM, and EDF Scheduling Modes ✅

| Aspect | Details |
|--------|----------|
| **Description** | Scheduler must support multiple real-time scheduling algorithms: Priority-based, Rate Monotonic (RM), and Earliest Deadline First (EDF) |
| **Modules** | `control_unit.v` - Mode selector and key calculator<br/>`priority_queue.v` - Maintains sorted queue per mode |
| **Tests** | `tb_control_unit_assert.v` - Verifies RM/EDF key calculations<br/>`test_priority_queue.py` - Golden model comparison |
| **Status** | ✅ **DONE** - All modes pass simulation |

### R02: SPI Command Interface ✅

| Aspect | Details |
|--------|----------|
| **Description** | Host must send commands (CREATE, MODIFY, RUN, STOP, DELETE, SLEEP, YIELD, SUSPEND, RESUME, CONFIGURE) and receive responses over SPI |
| **Modules** | `spi_slave_if.v` - SPI protocol termination<br/>`control_unit.v` - Command execution<br/>`fw/esp32/driver/scheduler.c` - Command generation |
| **Tests** | `tb_hw_scheduler_top.v` - Full protocol flow<br/>`test_rtl_regression.py` - Command coverage |
| **Status** | ✅ **DONE** - SPI protocol verified in simulation |

### R03: Ready Queue Sorting Invariant ✅

| Aspect | Details |
|--------|----------|
| **Description** | Priority queue must maintain sorted order by scheduling key; dequeue always returns highest-priority ready task |
| **Modules** | `priority_queue.v` - Sorted insertion<br/>`pq_cell.v` - Individual queue entry |
| **Tests** | `tb_priority_queue.v` - Sort invariant check<br/>`test_priority_queue.py` - Simultaneous enqueue+dequeue |
| **Status** | ✅ **DONE** - Sorting verified with complex access patterns |

### R04: Sleep Queue Wake-Up Timing ✅

| Aspect | Details |
|--------|----------|
| **Description** | Sleep queue must decrement counters each tick; tasks wake with deterministic ordering when counter expires |
| **Modules** | `sleep_queue.v` - Countdown management<br/>`timer.v` - Tick generation<br/>`control_unit.v` - Wake coordination |
| **Tests** | `tb_sleep_queue.v` - Wake order and multi-expiry<br/>`test_sleep_queue.py` - Timing verification |
| **Status** | ✅ **DONE** - Deterministic wake-up behavior validated |

### R05: Task Descriptor Storage ✅

| Aspect | Details |
|--------|----------|
| **Description** | Task table must store all task parameters (priority, period, deadline, WCET, status) and support concurrent read/write |
| **Modules** | `task_table.v` - Descriptor memory (16 slots) |
| **Tests** | `tb_task_table.v` - Memory access patterns<br/>`test_task_table.py` - Field validation<br/>`tb_phase1_vcd.v` - MODIFY command |
| **Status** | ✅ **DONE** - All fields stored and retrieved correctly |

### R06: IRQ Notification ✅

| Aspect | Details |
|--------|----------|
| **Description** | Scheduler must assert IRQ_N (active low) when preemption, deadline miss, or wake-up events occur; host reads IRQ reason |
| **Modules** | `interrupt_ctrl.v` - IRQ prioritization<br/>`control_unit.v` - Event detection |
| **Tests** | `tb_control_unit_assert.v` - IRQ codes (0x01 preempt, 0x03 deadline, 0x04 wake, 0x05 fast, 0x06 slow) |
| **Status** | ✅ **DONE** - All IRQ events verified |

### R07: Runtime Mode Switching ✅

| Aspect | Details |
|--------|----------|
| **Description** | Scheduling mode (Priority/RM/EDF) can be changed at runtime via CONFIGURE command without system reset |
| **Modules** | `control_unit.v` - Mode register<br/>`priority_queue.v` - Dynamic key calculation |
| **Tests** | `tb_control_unit_assert.v` - CONFIG mode switch test |
| **Status** | ✅ **DONE** - Mode changes verified in simulation |

### R08: Reset to Clean State ✅

| Aspect | Details |
|--------|----------|
| **Description** | RESET command clears all queues, task table, and resets mode to Priority with IRQ deasserted |
| **Modules** | `hw_scheduler_top.v` - Reset logic<br/>All submodules - State clearing |
| **Tests** | `tb_control_unit_assert.v` - State verification<br/>`tb_hw_scheduler_top.v` - Full reset flow |
| **Status** | ✅ **DONE** - Reset behavior deterministic |

### R09: Scan Chain for State Visibility ✅

| Aspect | Details |
|--------|----------|
| **Description** | Scan mode enabled via SPI; 256-bit shift path provides internal state readback for debugging |
| **Modules** | `scan_chain.v` - Scan flops and multiplexer<br/>`spi_slave_if.v` - Scan command handling |
| **Tests** | `tb_hw_scheduler_top.v` - Scan readout validation, no-X check |
| **Status** | ✅ **DONE** - Scan chain operational |

### R10: ESP32 Host Integration ✅

| Aspect | Details |
|--------|----------|
| **Description** | ESP32 can drive SPI protocol to communicate with scheduler; framework for task creation and context switching |
| **Modules** | `spi_slave_if.v` - SPI slave<br/>`fw/esp32/driver/scheduler.c` - Host driver<br/>`fw/esp32/app/main.c` - Application |
| **Tests** | `tb_hw_scheduler_top.v` - SPI protocol (framing, response timing)<br/>Simulation-based SPI stimulus |
| **Status** | ✅ **DONE** - SPI protocol validated; hardware bring-up pending |

---

## Verification Summary

| Phase | Component | Coverage | Result |
|-------|-----------|----------|--------|
| **Phase 1** | Core queues & memory | Unit tests | ✅ **PASS** |
| **Phase 2** | Control & integration | Integration tests | ✅ **PASS** |
| **Phase 3** | SPI & firmware | Protocol simulation | ✅ **PASS** |
| **Phase 4** | Comprehensive | Dual verification | ✅ **PASS** |

**Overall Status**: All requirements verified in simulation. Hardware-in-the-loop testing pending silicon bring-up.

---

## Notes

- **Simulation Environment**: Iverilog + Verilog testbenches, Python cocotb framework
- **Golden Model**: Python reference implementation for behavioral comparison
- **Waveform Analysis**: VCD files inspected for edge cases and determinism
- **Next Phase**: Post-silicon verification on physical prototype
