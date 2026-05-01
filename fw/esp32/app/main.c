#include "scheduler.h"
#include "esp_log.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"

#define TAG "main"
#define IRQ_PIN GPIO_NUM_4

static volatile uint8_t g_irq_reason;
static volatile bool    g_switch_needed;

// called from GPIO ISR context
static void IRAM_ATTR on_scheduler_irq(void *arg) {
    (void)arg;
    g_switch_needed = true;
}

// called from the host task after seeing g_switch_needed
static void handle_context_switch(void) {
    uint32_t reason = sched_query(0, 0x05);  // QUERY: irq reason
    g_irq_reason = (uint8_t)reason;
    ESP_LOGI(TAG, "context switch: irq_reason=0x%02x", g_irq_reason);
    // dequeue highest-priority ready task and mark it running
    sched_activate();
}

void app_main(void) {
    // task 1: periodic, priority 10, period=1000 ticks, deadline=1000, wcet=100
    task_cfg_t t1 = {
        .task_id     = 1,
        .priority    = 10,
        .period      = 1000,
        .deadline    = 1000,
        .wcet        = 100,
        .periodic    = true,
        .preemptable = true,
    };

    // task 2: periodic, higher priority, shorter period
    task_cfg_t t2 = {
        .task_id     = 2,
        .priority    = 14,
        .period      = 200,
        .deadline    = 200,
        .wcet        = 50,
        .periodic    = true,
        .preemptable = true,
    };

    ESP_ERROR_CHECK(sched_init(IRQ_PIN, on_scheduler_irq));

    // EDF mode, tick divider=99 (~100us ticks at 10MHz), preemption enabled,
    // all 8 ext_irq lines treated as fast (trigger immediate context switch)
    sched_configure(MODE_EDF, 99, SCHED_FLAG_PREEMPT, 0xFF);

    // create tasks (they start suspended)
    sched_create(&t1);
    sched_create(&t2);

    // move tasks to ready queue — must call resume before activate
    sched_resume(t1.task_id);
    sched_resume(t2.task_id);

    // start the tick timer, then activate the highest-priority task
    sched_run();
    sched_activate();

    // main loop: handle scheduler IRQs
    while (1) {
        if (g_switch_needed) {
            g_switch_needed = false;
            handle_context_switch();
        }
        vTaskDelay(pdMS_TO_TICKS(1));
    }
}
