# HARTS: Hardware Adaptive Real-Time Scheduler
**done for asic-hub sprint sp26**

A hardware scheduling coprocessor for real-time task management on edge devices.

## Overview

HARTS is an open-source hardware scheduler built for the SKY130 process node. It implements deterministic real-time scheduling in dedicated hardware, allowing a host CPU (like ESP32) to offload scheduling decisions and task management to a specialized coprocessor.

The scheduler supports multiple scheduling algorithms (Priority, Rate Monotonic, Earliest Deadline First) and provides a clean SPI interface for host communication.

## Project Structure

```
├── rtl/                 # Verilog RTL modules
│   ├── control_unit.v   # Main scheduling logic
│   ├── priority_queue.v # Ready queue management
│   ├── sleep_queue.v    # Timer-based sleeping tasks
│   ├── task_table.v     # Task descriptor storage
│   ├── timer.v          # Clock/tick generation
│   ├── interrupt_ctrl.v # IRQ generation
│   ├── spi_slave_if.v   # SPI protocol interface
│   └── ...
│
├── fw/                  # Firmware for host CPU
│   └── esp32/
│       ├── app/         # Application code
│       └── driver/      # ESP32 scheduler driver
│
├── verif/               # Verification & testing
│   ├── tb/              # Python/cocotb tests
│   ├── tb_verilog/      # Verilog testbenches
│   └── sim/             # Simulation artifacts
│
├── docs/                # In-depth documentation
│   ├── arch.md          # Hardware architecture
│   ├── spi_protocol.md  # SPI protocol specification
│   ├── spec_conformance.md # Development phases
│   ├── esp32_references.md # ESP32 driver references
│   └── traceability.md  # Requirements mapping
│
├── scripts/             # Build and utility scripts
├── flow/                # Design flow (synthesis, place & route)
└── Makefile             # Build targets
```

## Getting Started

### Building the Design

```bash
# Run all tests
make test-verilog

# Run specific test suite
make test-verilog-pq    # Priority queue tests
make test-verilog-sq    # Sleep queue tests
make test-verilog-tm    # Timer tests

# Run integration test
make test-verilog-top   # Full scheduler integration
```

### Understanding the Design

1. **Start here**: [Architecture Overview](docs/arch.md) - System design and module descriptions
2. **Protocol details**: [SPI Protocol](docs/spi_protocol.md) - Host communication specification
3. **Verification status**: [Spec Conformance](docs/spec_conformance.md) - Development phases
4. **Requirements mapping**: [Traceability Matrix](docs/traceability.md) - Requirements to implementation

## Architecture Highlights

### Core Components

- **Control Unit**: Orchestrates scheduling decisions and manages command flow
- **Priority Queue**: Maintains sorted ready task queue with stable ordering
- **Sleep Queue**: Handles timer-based task wake-up events
- **Task Table**: Stores task descriptors and runtime state
- **Timer**: Generates periodic tick events
- **Interrupt Controller**: Signals host CPU via IRQ for context switches
- **SPI Slave Interface**: Handles host command/response transactions

### Scheduling Modes

- **Priority Mode**: Static task priorities
- **Rate Monotonic (RM)**: Higher priority to tasks with shorter periods
- **Earliest Deadline First (EDF)**: Higher priority to earlier absolute deadlines

## Host Interface

The scheduler communicates with the host CPU (ESP32) via SPI using a simple command/response protocol:

- **Commands**: Create/modify/delete tasks, sleep, yield, suspend, resume, query status
- **Responses**: Task status, IRQ events (preemption, deadline miss, wakeup)
- **Interrupts**: Active-low IRQ signal notifies host of scheduling events

## Verification Status

All phases pass simulation. Hardware bring-up pending physical tape-out.

## License

TBD

## Contributing

This is an open-source hardware project. 

---

**For detailed technical information, see the [docs/](docs/) directory.**
