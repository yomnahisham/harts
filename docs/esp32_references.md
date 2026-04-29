# ESP32 Host Driver References

This document lists the key resources used to implement the ESP32 host-side driver for communicating with the HARTS scheduler coprocessor.

## Official Documentation

### ESP32 Technical Reference Manual
**URL**: https://www.espressif.com/sites/default/files/documentation/esp32_technical_reference_manual_en.pdf

**Key Sections**:
- SPI Master/Slave Peripheral (Chapter 7)
- GPIO & Interrupt Controller
- Clock tree and clock gating

### ESP-IDF SPI Master API
**URL**: https://docs.espressif.com/projects/esp-idf/en/stable/esp32/api-reference/peripherals/spi_master.html

**Key Components**:
- SPI host driver architecture
- Transaction model and queuing
- DMA support (for bulk transfers)

### ESP-IDF SPI Master Header (source)
**URL**: https://github.com/espressif/esp-idf/blob/master/components/esp_driver_spi/include/driver/spi_master.h

**Key Functions**:
```c
spi_bus_initialize()      // Initialize SPI bus
spi_bus_add_device()      // Add slave device
spi_device_transmit()     // Synchronous transfer
spi_device_queue_trans()  // Queue async transfer
spi_device_get_trans_result() // Retrieve result
```

## Implementation Notes

### SPI Configuration
- **Mode**: SPI Mode 0 (CPOL=0, CPHA=0)
- **Frequency**: 10 MHz (configurable per device)
- **Bus**: SPI2 (HSPI) typically used for application devices
- **DMA**: Enabled for transfers > 4 bytes

### Transaction Model
The ESP32 SPI driver uses a queue-based transaction model:
1. Prepare transaction structure (`spi_transaction_t`)
2. Call `spi_device_transmit()` (blocking) or `spi_device_queue_trans()` (async)
3. For async: call `spi_device_get_trans_result()` to retrieve response

### IRQ Handling
- Scheduler IRQ connected to GPIO pin (typically GPIO25 or GPIO26)
- GPIO configured as input with rising-edge or falling-edge detection
- IRQ handler reads scheduler IRQ reason via QUERY command
- Context switch performed in interrupt context or deferred (RTOS task)

## Driver Architecture

The HARTS ESP32 driver (`fw/esp32/driver/scheduler.c`) provides:

**Initialization**:
```c
void scheduler_init(spi_device_handle_t spi_dev, int irq_pin);
```

**Command Interface**:
```c
void scheduler_configure(spi_device_handle_t dev, uint8_t mode, uint8_t tick_div, uint8_t flags);
void scheduler_create_task(spi_device_handle_t dev, task_params_t *task);
void scheduler_run(spi_device_handle_t dev, uint8_t task_id);
// ... more command functions
```

**Query Interface**:
```c
uint32_t scheduler_query(spi_device_handle_t dev, uint8_t selector);
uint8_t scheduler_get_running_task(spi_device_handle_t dev);
```

**IRQ Handler**:
```c
void scheduler_irq_handler(void *arg);  // GPIO ISR
```

## Hardware Setup

### Pinout
| Signal | ESP32 Pin | Note |
|--------|-----------|------|
| SCLK | GPIO18 | SPI2 clock |
| MOSI | GPIO23 | SPI2 MOSI |
| MISO | GPIO19 | SPI2 MISO |
| CS_N | GPIO5 | SPI2 CS0 (configurable) |
| IRQ_N | GPIO25 | Interrupt (active low) |

## Build & Integration

**Compilation**:
```bash
# Part of ESP-IDF project, compiled with application
idf.py build
```

**Main Application** (`fw/esp32/app/main.c`):
- Initializes SPI and GPIO
- Creates scheduler driver instance
- Sends configuration and task creation commands
- Handles scheduler interrupt events
- Implements context switching logic

## Testing & Validation

Driver tested in simulation via:
- `tb_verilog/tb_hw_scheduler_top.v` - SPI protocol verification
- `tb/*.py` - Golden model comparison

Hardware testing planned for post-silicon bring-up phase.
