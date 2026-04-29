#include "scheduler.h"

#include <string.h>
#include "driver/spi_master.h"
#include "driver/gpio.h"
#include "esp_log.h"

#define TAG "harts"

#define PIN_NUM_MISO 19
#define PIN_NUM_MOSI 23
#define PIN_NUM_CLK  18
#define PIN_NUM_CS    5

static spi_device_handle_t g_spi;

// ---- low-level SPI ----------------------------------------------------------
// The hardware shifts MSB first. ESP32 is little-endian, so a raw &uint32_t
// pointer would send the LSB first — wrong. We must byte-swap before sending
// and byte-swap after receiving.
static uint32_t sched_xfer(uint32_t tx_word) {
    spi_transaction_t t;
    memset(&t, 0, sizeof(t));
    t.flags  = SPI_TRANS_USE_TXDATA | SPI_TRANS_USE_RXDATA;
    t.length = 32;
    // pack bytes MSB-first into the 4-byte tx_data field
    t.tx_data[0] = (tx_word >> 24) & 0xff;
    t.tx_data[1] = (tx_word >> 16) & 0xff;
    t.tx_data[2] = (tx_word >>  8) & 0xff;
    t.tx_data[3] =  tx_word        & 0xff;
    spi_device_transmit(g_spi, &t);
    return ((uint32_t)t.rx_data[0] << 24) |
           ((uint32_t)t.rx_data[1] << 16) |
           ((uint32_t)t.rx_data[2] <<  8) |
            (uint32_t)t.rx_data[3];
}

// HARTS SPI protocol: MISO during transaction N carries the response to
// command N-1 (the slave loads rsp_word on the falling edge of CS).
// To read the response to the last command, send a NOP and return its MISO.
static uint32_t sched_xfer_read_rsp(uint32_t tx_word) {
    sched_xfer(tx_word);
    return sched_xfer(0x00000000u); // NOP clocks out the previous response
}

static uint32_t mk_word(uint8_t op, uint8_t task_id, uint8_t a, uint8_t b, uint8_t c) {
    return ((uint32_t)(op & 0xfu) << 28) |
           ((uint32_t)(task_id & 0xfu) << 24) |
           ((uint32_t)a << 16) |
           ((uint32_t)b <<  8) |
            (uint32_t)c;
}

static uint32_t mk_task_word1(uint8_t op, const task_cfg_t *cfg) {
    return ((uint32_t)(op & 0xfu) << 28) |
           ((uint32_t)(cfg->task_id & 0xfu) << 24) |
           ((uint32_t)(cfg->priority & 0xfu) << 20) |
           ((uint32_t)(cfg->periodic    ? 1u : 0u) << 19) |
           ((uint32_t)(cfg->preemptable ? 1u : 0u) << 18) |
            (uint32_t)(cfg->deadline & 0xffffu);
}

// ---- init -------------------------------------------------------------------
sched_err_t sched_init(gpio_num_t irq_pin, gpio_isr_t isr_handler) {
    spi_bus_config_t buscfg = {
        .mosi_io_num   = PIN_NUM_MOSI,
        .miso_io_num   = PIN_NUM_MISO,
        .sclk_io_num   = PIN_NUM_CLK,
        .quadwp_io_num = -1,
        .quadhd_io_num = -1,
    };
    spi_device_interface_config_t devcfg = {
        .clock_speed_hz = 10 * 1000 * 1000,
        .mode           = 0,         // SPI mode 0: CPOL=0 CPHA=0
        .spics_io_num   = PIN_NUM_CS,
        .queue_size     = 1,
    };
    if (spi_bus_initialize(SPI2_HOST, &buscfg, SPI_DMA_DISABLED) != ESP_OK) {
        ESP_LOGE(TAG, "spi_bus_initialize failed");
        return SCHED_ERR;
    }
    if (spi_bus_add_device(SPI2_HOST, &devcfg, &g_spi) != ESP_OK) {
        ESP_LOGE(TAG, "spi_bus_add_device failed");
        return SCHED_ERR;
    }

    gpio_config_t io = {
        .pin_bit_mask = (1ULL << irq_pin),
        .mode         = GPIO_MODE_INPUT,
        .pull_up_en   = GPIO_PULLUP_ENABLE,  // irq_n is active-low open-drain
        .intr_type    = GPIO_INTR_NEGEDGE,
    };
    if (gpio_config(&io) != ESP_OK) return SCHED_ERR;

    if (isr_handler) {
        gpio_install_isr_service(0);
        if (gpio_isr_handler_add(irq_pin, isr_handler, NULL) != ESP_OK) {
            ESP_LOGE(TAG, "gpio_isr_handler_add failed");
            return SCHED_ERR;
        }
    }

    return SCHED_OK;
}

// ---- scheduler control ------------------------------------------------------
sched_err_t sched_configure(sched_mode_t mode, uint8_t tick_div, uint8_t flags) {
    sched_xfer(mk_word(0x1, 0, (uint8_t)mode, tick_div, flags));
    return SCHED_OK;
}

sched_err_t sched_run(void) {
    sched_xfer(mk_word(0x2, 0, 0, 0, 0));
    return SCHED_OK;
}

sched_err_t sched_stop(void) {
    sched_xfer(mk_word(0x3, 0, 0, 0, 0));
    return SCHED_OK;
}

sched_err_t sched_reset(void) {
    // safety key 0xAD must be in param_a; hardware rejects any other value
    sched_xfer(mk_word(0xf, 0, 0xad, 0, 0));
    return SCHED_OK;
}

// ---- task lifecycle ---------------------------------------------------------
sched_err_t sched_create(const task_cfg_t *cfg) {
    uint32_t w1 = mk_task_word1(0x4, cfg);
    uint32_t w2 = ((uint32_t)cfg->period << 16) | (uint32_t)cfg->wcet;
    sched_xfer(w1);
    sched_xfer(w2);
    return SCHED_OK;
}

sched_err_t sched_modify(const task_cfg_t *cfg) {
    uint32_t w1 = mk_task_word1(0x6, cfg);
    uint32_t w2 = ((uint32_t)cfg->period << 16) | (uint32_t)cfg->wcet;
    sched_xfer(w1);
    sched_xfer(w2);
    return SCHED_OK;
}

sched_err_t sched_delete(uint8_t task_id) {
    sched_xfer(mk_word(0x5, task_id, 0, 0, 0));
    return SCHED_OK;
}

sched_err_t sched_resume(uint8_t task_id) {
    sched_xfer(mk_word(0xb, task_id, 0, 0, 0));
    return SCHED_OK;
}

sched_err_t sched_suspend(uint8_t task_id) {
    sched_xfer(mk_word(0xa, task_id, 0, 0, 0));
    return SCHED_OK;
}

sched_err_t sched_activate(void) {
    // OP_ACTIVATE pops the pq head and sets it running; task_id field ignored
    sched_xfer(mk_word(0xc, 0, 0, 0, 0));
    return SCHED_OK;
}

sched_err_t sched_yield(uint8_t task_id) {
    sched_xfer(mk_word(0x9, task_id, 0, 0, 0));
    return SCHED_OK;
}

sched_err_t sched_sleep_long(uint8_t task_id, uint32_t ticks) {
    sched_xfer(mk_word(0x7, task_id, 0, 0, 0));
    sched_xfer(ticks);
    return SCHED_OK;
}

sched_err_t sched_sleep_short(uint8_t task_id, uint32_t ticks) {
    // 24-bit count packed into cmd[23:0]; no second word required
    uint32_t w = ((uint32_t)(0x8u) << 28) |
                 ((uint32_t)(task_id & 0xfu) << 24) |
                 (ticks & 0x00ffffffu);
    sched_xfer(w);
    return SCHED_OK;
}

// ---- query ------------------------------------------------------------------
uint32_t sched_query(uint8_t task_id, uint8_t sel) {
    // send QUERY, then a NOP to clock out the response (hardware returns N-1)
    return sched_xfer_read_rsp(mk_word(0xd, task_id, sel, 0, 0));
}
