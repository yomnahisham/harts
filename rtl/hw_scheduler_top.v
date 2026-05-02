// hw_scheduler_top - HARTS scheduler wrapper
//TODO: rename module to harts
module hw_scheduler_top (
    input wire clk,
    input wire rst_n,
    input wire sclk,
    input wire cs_n,
    input wire mosi,
    output wire miso,
    input wire [7:0] ext_irq,
    output wire irq_n,
    input wire scan_en,
    input wire scan_in,
    output wire scan_out
);
    wire cmd_valid;
    wire [31:0] cmd_word;
    wire cmd_word2_valid;
    wire [31:0] cmd_word2;
    wire [31:0] rsp_word;
    reg waiting_word2;
    reg ctrl_cmd_valid;
    reg [31:0] ctrl_cmd_word;
    reg ctrl_cmd_word2_valid;
    reg [31:0] ctrl_cmd_word2;

    wire timer_enable;
    wire [15:0] tick_divider;
    wire tick_pulse;
    reg tick_pulse_r;
    wire [15:0] tick_counter;

    // 2-FF synchronizer from pad rst_n, then parallel second-stage flops (same value, lower fanout per net)
    reg sync_rst_d1;
    reg sync_rst_d2a;
    reg sync_rst_d2b;
    reg sync_rst_d2c;
    reg sync_rst_d2d_ctrl;
    reg sync_rst_d2d_scan;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sync_rst_d1 <= 1'b0;
            sync_rst_d2a <= 1'b0;
            sync_rst_d2b <= 1'b0;
            sync_rst_d2c <= 1'b0;
            sync_rst_d2d_ctrl <= 1'b0;
            sync_rst_d2d_scan <= 1'b0;
        end else begin
            sync_rst_d1 <= 1'b1;
            sync_rst_d2a <= sync_rst_d1;
            sync_rst_d2b <= sync_rst_d1;
            sync_rst_d2c <= sync_rst_d1;
            sync_rst_d2d_ctrl <= sync_rst_d1;
            sync_rst_d2d_scan <= sync_rst_d1;
        end
    end

    wire rst_spi_tm_n = sync_rst_d2a; // SPI, timer, tick_pulse_r
    wire rst_pq_n = sync_rst_d2b; // priority_queue
    wire rst_sq_irq_n = sync_rst_d2c; // sleep_queue, interrupt_ctrl
    wire rst_ctrl_n = sync_rst_d2d_ctrl; // control_unit
    wire rst_glue_scan_n = sync_rst_d2d_scan; // SPI→ctrl glue, scan_chain

    always @(posedge clk) begin
        if (!rst_spi_tm_n)
            tick_pulse_r <= 1'b0;
        else
            tick_pulse_r <= tick_pulse;
    end

    wire pq_enqueue;
    wire pq_dequeue;
    wire pq_flush;
    wire [3:0] pq_enq_id;
    wire [15:0] pq_enq_key;
    wire [3:0] pq_head_id;
    wire [15:0] pq_head_key;
    wire pq_head_valid;
    wire [4:0] pq_depth;

    reg pq_enqueue_r;
    reg [3:0] pq_enq_id_r;
    reg [15:0] pq_enq_key_r;

    always @(posedge clk) begin
        if (!rst_pq_n) begin
            pq_enqueue_r <= 1'b0;
            pq_enq_id_r <= 4'd0;
            pq_enq_key_r <= 16'd0;
        end else begin
            pq_enqueue_r <= pq_enqueue;
            pq_enq_id_r <= pq_enq_id;
            pq_enq_key_r <= pq_enq_key;
        end
    end

    wire sq_enqueue;
    wire [3:0] sq_enq_id;
    wire [31:0] sq_enq_counter;
    wire sq_flush;
    wire sq_wake_valid;
    wire [3:0] sq_wake_id;
    wire [4:0] sq_depth;

    wire irq_pending;
    wire fast_irq;
    wire [2:0] irq_index;
    wire [7:0] irq_reason;
    wire [3:0] current_task;
    wire [7:0] fast_mask_r;

    spi_slave_if u_spi (
        .clk(clk),
        .rst_n(rst_spi_tm_n),
        .sclk(sclk),
        .cs_n(cs_n),
        .mosi(mosi),
        .miso(miso),
        .cmd_valid(cmd_valid),
        .cmd_word(cmd_word),
        .rsp_word(rsp_word)
    );

    always @(posedge clk) begin
        if (!rst_glue_scan_n) begin
            waiting_word2 <= 1'b0;
            ctrl_cmd_valid <= 1'b0;
            ctrl_cmd_word <= 32'd0;
            ctrl_cmd_word2_valid <= 1'b0;
            ctrl_cmd_word2 <= 32'd0;
        end else begin
            ctrl_cmd_valid <= 1'b0;
            ctrl_cmd_word2_valid <= 1'b0;

            if (cmd_valid) begin
                if (waiting_word2) begin
                    ctrl_cmd_word2_valid <= 1'b1;
                    ctrl_cmd_word2 <= cmd_word;
                    waiting_word2 <= 1'b0;
                end else begin
                    ctrl_cmd_valid <= 1'b1;
                    ctrl_cmd_word <= cmd_word;
                    if (cmd_word[31:28] == 4'h4 || cmd_word[31:28] == 4'h6 || cmd_word[31:28] == 4'h7) begin
                        waiting_word2 <= 1'b1;
                    end
                end
            end
        end
    end

    timer u_timer (
        .clk(clk),
        .rst_n(rst_spi_tm_n),
        .enable(timer_enable),
        .tick_divider(tick_divider),
        .tick_pulse(tick_pulse),
        .tick_counter(tick_counter)
    );


    priority_queue #(.DEPTH(6)) u_pq (
        .clk(clk),
        .rst_n(rst_pq_n),
        .enqueue(pq_enqueue_r),
        .dequeue(pq_dequeue),
        .flush(pq_flush),
        .enq_id(pq_enq_id_r),
        .enq_key(pq_enq_key_r),
        .head_id(pq_head_id),
        .head_key(pq_head_key),
        .head_valid(pq_head_valid),
        .depth(pq_depth)
    );

    sleep_queue u_sq (
        .clk(clk),
        .rst_n(rst_sq_irq_n),
        .flush(sq_flush),
        .enqueue(sq_enqueue),
        .tick(tick_pulse_r),
        .enq_id(sq_enq_id),
        .enq_count(sq_enq_counter),
        .wake_valid(sq_wake_valid),
        .wake_id(sq_wake_id),
        .depth(sq_depth)
    );

    interrupt_ctrl u_irq_ctrl (
        .clk(clk),
        .rst_n(rst_sq_irq_n),
        .ext_irq(ext_irq),
        .fast_mask(fast_mask_r),
        .irq_pending(irq_pending),
        .fast_irq(fast_irq),
        .irq_index(irq_index)
    );

    control_unit u_ctrl (
        .clk(clk),
        .rst_n(rst_ctrl_n),
        .cmd_valid(ctrl_cmd_valid),
        .cmd_word(ctrl_cmd_word),
        .cmd_word2_valid(ctrl_cmd_word2_valid),
        .cmd_word2(ctrl_cmd_word2),
        .rsp_word(rsp_word),
        .need_word2(),
        .tick_pulse(tick_pulse_r),
        .irq_pending(irq_pending),
        .fast_irq(fast_irq),
        .pq_head_id(pq_head_id),
        .pq_head_key(pq_head_key),
        .pq_head_valid(pq_head_valid),
        .pq_depth(pq_depth),
        .pq_enqueue(pq_enqueue),
        .pq_dequeue(pq_dequeue),
        .pq_flush(pq_flush),
        .pq_enq_id(pq_enq_id),
        .pq_enq_key(pq_enq_key),
        .sq_wake_valid(sq_wake_valid),
        .sq_wake_id(sq_wake_id),
        .sq_depth(sq_depth),
        .sq_enqueue(sq_enqueue),
        .sq_enq_id(sq_enq_id),
        .sq_enq_counter(sq_enq_counter),
        .sq_flush(sq_flush),
        .timer_enable(timer_enable),
        .tick_divider(tick_divider),
        .irq_n(irq_n),
        .irq_reason(irq_reason),
        .current_task(current_task),
        .fast_mask(fast_mask_r)
    );

    wire [255:0] scan_parallel = {
        198'd0,
        irq_reason,
        current_task,
        pq_head_id,
        pq_head_key,
        tick_counter,
        pq_depth,
        sq_depth
    };

    scan_chain #(.WIDTH(256)) u_scan (
        .clk(clk),
        .rst_n(rst_glue_scan_n),
        .scan_en(scan_en),
        .scan_in(scan_in),
        .parallel_in(scan_parallel),
        .scan_out(scan_out)
    );
endmodule
