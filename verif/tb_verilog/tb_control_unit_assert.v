`timescale 1ns/1ps
module tb_control_unit_assert;
    reg clk = 0;
    reg rst_n = 0;
    reg cmd_valid = 0;
    reg [31:0] cmd_word = 0;
    reg cmd_word2_valid = 0;
    reg [31:0] cmd_word2 = 0;
    wire [31:0] rsp_word;
    wire need_word2;
    reg tick_pulse = 0;
    reg irq_pending = 0;
    reg fast_irq = 0;
    reg [3:0] pq_head_id = 0;
    reg [15:0] pq_head_key = 0;
    reg pq_head_valid = 0;
    reg [4:0] pq_depth = 0;
    wire pq_enqueue;
    wire pq_dequeue;
    wire pq_flush;
    wire [3:0] pq_enq_id;
    wire [15:0] pq_enq_key;
    reg sq_wake_valid = 0;
    reg [3:0] sq_wake_id = 0;
    reg [4:0] sq_depth = 0;
    wire sq_enqueue;
    wire [3:0] sq_enq_id;
    wire [31:0] sq_enq_counter;
    wire sq_flush;
    wire timer_enable;
    wire [15:0] tick_divider;
    wire irq_n;
    wire [7:0] irq_reason;
    wire [3:0] current_task;
    wire [7:0] fast_mask;
    reg seen_pending_word2 = 0;
    reg seen_need_word2 = 0;

    control_unit dut (
        .clk(clk),
        .rst_n(rst_n),
        .cmd_valid(cmd_valid),
        .cmd_word(cmd_word),
        .cmd_word2_valid(cmd_word2_valid),
        .cmd_word2(cmd_word2),
        .rsp_word(rsp_word),
        .need_word2(need_word2),
        .tick_pulse(tick_pulse),
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
        .fast_mask(fast_mask)
    );

    always #5 clk = ~clk;

    task send_cmd(input [31:0] w);
    begin
        cmd_word = w;
        cmd_valid = 1;
        @(posedge clk);
        @(posedge clk);
        @(negedge clk);
        cmd_valid = 0;
    end
    endtask

    task send_word2(input [31:0] w2);
    begin
        cmd_word2 = w2;
        cmd_word2_valid = 1;
        @(posedge clk);
        @(posedge clk);
        @(negedge clk);
        cmd_word2_valid = 0;
    end
    endtask

    integer i;
    always @(posedge clk) begin
        if (rst_n) begin
            if (dut.pending_word2) seen_pending_word2 <= 1'b1;
            if (need_word2) seen_need_word2 <= 1'b1;
            if (^irq_n === 1'bx || ^need_word2 === 1'bx || ^pq_enqueue === 1'bx || ^sq_enqueue === 1'bx) begin
                $display("fail unknown control outputs");
                $fatal(1);
            end
            if (pq_enqueue && sq_enqueue) begin
                $display("fail enqueue collision pq and sq");
                $fatal(1);
            end
            if (need_word2 && !dut.pending_word2) begin
                $display("fail need_word2 without pending state");
                $fatal(1);
            end
            if (dut.pending_word2 && dut.pending_opcode != 4'h4 && dut.pending_opcode != 4'h6 && dut.pending_opcode != 4'h7) begin
                $display("fail illegal pending opcode");
                $fatal(1);
            end
        end
    end

    initial begin
        $dumpfile("tb_control_unit_assert.vcd");
        $dumpvars(0, tb_control_unit_assert);
        repeat (4) @(posedge clk);
        rst_n = 1;
        @(posedge clk);

        send_cmd(32'h1063_0180);
        send_cmd(32'h2000_0000);

        pq_depth = 5'd3;
        sq_depth = 5'd2;
        send_cmd(32'hd002_0000);
        @(posedge clk);
        if (rsp_word !== 32'h0000_0003) begin
            $display("fail query pq depth response");
            $fatal(1);
        end
        send_cmd(32'hd003_0000);
        @(posedge clk);
        if (rsp_word !== 32'h0000_0002) begin
            $display("fail query sq depth response");
            $fatal(1);
        end

        send_cmd(32'h410a_0064);
        for (i = 0; i < 8; i = i + 1) begin
            tick_pulse = 1;
            @(posedge clk);
            @(negedge clk);
            tick_pulse = 0;
            @(posedge clk);
        end
        if (!seen_need_word2) begin
            $display("fail missing multiword create request");
            $fatal(1);
        end
        send_word2(32'h03e8_0064);
        @(posedge clk);
        if (rsp_word !== 32'h0000_c004) begin
            $display("fail create completion response");
            $fatal(1);
        end

        send_cmd(32'hc100_0000);
        pq_head_valid = 1;
        pq_head_id = 1;
        pq_head_key = 16'h00ff;
        @(posedge clk);
        pq_head_valid = 0;

        irq_pending = 1;
        fast_irq = 1;
        @(posedge clk);
        irq_pending = 0;
        if (irq_n !== 1'b0 || irq_reason !== 8'h05) begin
            $display("fail fast external irq reason");
            $fatal(1);
        end

        irq_pending = 1;
        fast_irq = 0;
        @(posedge clk);
        irq_pending = 0;
        if (irq_n !== 1'b0 || irq_reason !== 8'h06) begin
            $display("fail slow external irq reason");
            $fatal(1);
        end

        sq_wake_valid = 1;
        sq_wake_id = 1;
        @(posedge clk);
        sq_wake_valid = 0;

        // ---------------------------------------------------------------
        // RM mode: pq_enq_key must equal ~period
        // ---------------------------------------------------------------
        send_cmd(32'hf0ad_0000);           // RESET (safe word = 0xAD)
        @(posedge clk);
        // CONFIG: fast_mask=0xFF [27:20], sched_mode=RM=1 [17:16], tick_div=1 [15:8], flags=0 [7:0]
        send_cmd(32'h1ff1_0100);
        // CREATE task_id=1, prio=5, periodic=1, preemptable=0, deadline=100
        send_cmd(32'h4158_0064);
        send_word2(32'h00c8_0014);         // period=200, wcet=20
        // RESUME task_id=1 → enqueues to PQ; in RM mode key = ~period
        send_cmd(32'hb100_0000);
        if (pq_enq_key !== ~16'd200 || pq_enq_id !== 4'd1 || !pq_enqueue) begin
            $display("fail RM mode pq_enq_key: got %h expected %h", pq_enq_key, ~16'd200);
            $fatal(1);
        end

        // ---------------------------------------------------------------
        // EDF mode: pq_enq_key must equal ~(tick_count + deadline)
        // tick_count is still 0 (no ticks since last RESET)
        // ---------------------------------------------------------------
        // CONFIG: fast_mask=0xFF, sched_mode=EDF=2 [17:16], tick_div=1, flags=0
        send_cmd(32'h1ff2_0100);
        // CREATE task_id=2, prio=3, periodic=1, preemptable=0, deadline=50
        send_cmd(32'h4238_0032);
        send_word2(32'h0064_000a);         // period=100, wcet=10
        // RESUME task_id=2 → key = ~(tick_count + deadline) = ~(0+50)
        send_cmd(32'hb200_0000);
        if (pq_enq_key !== ~16'd50 || pq_enq_id !== 4'd2 || !pq_enqueue) begin
            $display("fail EDF mode pq_enq_key: got %h expected %h", pq_enq_key, ~16'd50);
            $fatal(1);
        end

        // ---------------------------------------------------------------
        // Preemption IRQ: flags_reg[7]=1, new pq_head != current_task
        // ---------------------------------------------------------------
        send_cmd(32'hf0ad_0000);           // RESET
        @(posedge clk);
        // CONFIG: sched_mode=0, flags=0x80 (PREEMPT), fast_mask=0xFF, tick_div=1
        send_cmd(32'h1ff0_0180);
        send_cmd(32'h2000_0000);           // RUN
        pq_head_valid = 1; pq_head_id = 4'd3; pq_head_key = 16'h0010;
        send_cmd(32'hc000_0000);           // ACTIVATE → current_task=3
        @(posedge clk);
        pq_head_valid = 0;
        if (dut.current_task !== 4'd3) begin
            $display("fail preempt setup: current_task=%0d", dut.current_task);
            $fatal(1);
        end
        // present a different task at PQ head → preemption check fires
        pq_head_valid = 1; pq_head_id = 4'd7; pq_head_key = 16'h00ff;
        @(posedge clk);
        pq_head_valid = 0;
        if (irq_n !== 1'b0 || irq_reason !== 8'h01) begin
            $display("fail preempt IRQ: irq_n=%b irq_reason=%h", irq_n, irq_reason);
            $fatal(1);
        end

        // ---------------------------------------------------------------
        // Deadline miss IRQ: task expires exactly at abs_deadline tick
        // ---------------------------------------------------------------
        send_cmd(32'hf0ad_0000);           // RESET
        @(posedge clk);
        // CONFIG: sched_mode=0, flags=0, no preemption
        send_cmd(32'h1ff0_0100);
        // CREATE task_id=3, prio=7, aperiodic, deadline=4
        // [31:28]=4 [27:24]=3 [23:20]=7 [19]=0 [18]=0 [15:0]=4
        send_cmd(32'h4370_0004);
        send_word2(32'h0000_0003);         // period=0, wcet=3
        // RESUME → abs_deadline = tick_count(0)+4 = 4
        send_cmd(32'hb300_0000);
        // ACTIVATE → current_task=3, status=running
        pq_head_valid = 1; pq_head_id = 4'd3; pq_head_key = 16'h0007;
        send_cmd(32'hc000_0000);
        @(posedge clk);
        pq_head_valid = 0;
        // ticks 1-3: no deadline miss (tick_count+1 < 4)
        repeat (3) begin
            @(negedge clk); tick_pulse = 1;
            @(posedge clk); @(negedge clk); tick_pulse = 0;
            @(posedge clk);
            if (irq_reason === 8'h03) begin
                $display("fail premature deadline miss at tick_count=%0d", dut.tick_count);
                $fatal(1);
            end
        end
        // tick 4: tick_count goes 3→4, equals abs_deadline=4 → miss fires
        @(negedge clk); tick_pulse = 1;
        @(posedge clk); @(negedge clk); tick_pulse = 0; @(posedge clk);
        if (irq_n !== 1'b0 || irq_reason !== 8'h03) begin
            $display("fail deadline miss IRQ: irq_n=%b irq_reason=%h tick_count=%0d",
                     irq_n, irq_reason, dut.tick_count);
            $fatal(1);
        end

        // ---------------------------------------------------------------
        // Final RESET and state check
        // ---------------------------------------------------------------
        send_cmd(32'hf0ad_0000);
        @(posedge clk);
        if (dut.sched_mode !== 2'b00 || dut.flags_reg !== 8'd0 || dut.current_task !== 4'hf || dut.timer_enable !== 1'b0) begin
            $display("fail reset state restoration");
            $fatal(1);
        end

        repeat (10) @(posedge clk);
        $display("pass");
        $finish;
    end
endmodule
