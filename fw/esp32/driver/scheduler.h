#ifndef SCHEDULER_H
#define SCHEDULER_H

#include <stdint.h>
#include <stdbool.h>
#include "driver/gpio.h"

// ---- error codes ------------------------------------------------------------
typedef enum {
    SCHED_OK  =  0,
    SCHED_ERR = -1,
} sched_err_t;

// ---- scheduling modes (CONFIG param_a[1:0]) ---------------------------------
typedef enum {
    MODE_PRIORITY = 0,
    MODE_RM       = 1,
    MODE_EDF      = 2,
    MODE_LLF      = 3,
} sched_mode_t;

// ---- flag bits (CONFIG param_c) ---------------------------------------------
#define SCHED_FLAG_PREEMPT      (1u << 7)
#define SCHED_FLAG_DEADLINE_IRQ (1u << 6)
#define SCHED_FLAG_SCAN_EN      (1u << 5)
#define SCHED_FLAG_LLF_THRESH   (1u << 4)

// ---- IRQ reason codes (QUERY 0x05) -----------------------------------------
#define SCHED_IRQ_PREEMPT       0x01
#define SCHED_IRQ_YIELD         0x02
#define SCHED_IRQ_DEADLINE_MISS 0x03
#define SCHED_IRQ_WAKEUP        0x04
#define SCHED_IRQ_FAST_EXT      0x05
#define SCHED_IRQ_SLOW_EXT      0x06

// ---- task descriptor --------------------------------------------------------
typedef struct {
    uint8_t  task_id;
    uint8_t  priority;    // 4-bit [0..15]
    uint16_t period;      // ticks
    uint16_t deadline;    // relative deadline in ticks
    uint16_t wcet;        // worst-case execution time in ticks
    bool     periodic;
    bool     preemptable;
} task_cfg_t;

// ---- init -------------------------------------------------------------------
// irq_pin: GPIO number wired to HARTS irq_n (active-low)
// isr_handler: called from ISR context when irq_n asserts; may be NULL
sched_err_t sched_init(gpio_num_t irq_pin, gpio_isr_t isr_handler);

// ---- scheduler control ------------------------------------------------------
sched_err_t sched_configure(sched_mode_t mode, uint8_t tick_div, uint8_t flags);
sched_err_t sched_run(void);
sched_err_t sched_stop(void);
// safe reset: hardware requires 0xAD key; clears all state
sched_err_t sched_reset(void);

// ---- task lifecycle ---------------------------------------------------------
sched_err_t sched_create(const task_cfg_t *cfg);
sched_err_t sched_modify(const task_cfg_t *cfg);
sched_err_t sched_delete(uint8_t task_id);
// resume: transition suspended task to ready and enqueue in priority queue
sched_err_t sched_resume(uint8_t task_id);
sched_err_t sched_suspend(uint8_t task_id);
// activate: dequeue highest-priority ready task and mark it running
// does NOT take a task_id — hardware always pops the queue head
sched_err_t sched_activate(void);
sched_err_t sched_yield(uint8_t task_id);
// sleep_long: 32-bit tick count via second word (up to ~4B ticks)
sched_err_t sched_sleep_long(uint8_t task_id, uint32_t ticks);
// sleep_short: 24-bit count packed in first word, no second word needed
sched_err_t sched_sleep_short(uint8_t task_id, uint32_t ticks);

// ---- query ------------------------------------------------------------------
// sends QUERY then a NOP to clock out the response (hardware returns N-1)
uint32_t sched_query(uint8_t task_id, uint8_t sel);

#endif
