`timescale 1ns/1ps
module tb_phase1_vcd;
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
    integer seen_sq_enqueue;
    reg [31:0] seen_sq_counter;
    reg [3:0] seen_sq_id;

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

    always @(posedge clk) begin
        if (rst_n && sq_enqueue === 1'b1) begin
            seen_sq_enqueue = 1;
            seen_sq_counter = sq_enq_counter;
            seen_sq_id = sq_enq_id;
        end
    end

    initial begin
        $dumpfile("tb_phase1_vcd.vcd");
        $dumpvars(0, tb_phase1_vcd);
        seen_sq_enqueue = 0;
        seen_sq_counter = 32'd0;
        seen_sq_id = 4'd0;

        repeat (4) @(posedge clk);
        rst_n = 1;
        @(posedge clk);

        // MODIFY task_id=2, prio=10, periodic=1, preemptable=0, deadline=16'h1234
        send_cmd(32'h62a8_1234);
        if (need_word2 !== 1'b1) begin
            $display("fail modify did not request second word");
            $finish(1);
        end
        // period=16'habcd, wcet=16'h00ef
        send_word2(32'habcd_00ef);
        repeat (2) @(posedge clk);

        if (rsp_word !== 32'h0000_c006) begin
            $display("fail modify response expected c006 got %h", rsp_word);
            $finish(1);
        end

        if (dut.u_task_table.priority_mem[2] !== 4'ha ||
            dut.u_task_table.type_mem[2] !== 1'b1 ||
            dut.u_task_table.pre_mem[2] !== 1'b0 ||
            dut.u_task_table.deadline_mem[2] !== 16'h1234 ||
            dut.u_task_table.period_mem[2] !== 16'habcd ||
            dut.u_task_table.wcet_mem[2] !== 16'h00ef) begin
            $display("debug prio=%h type=%b pre=%b dl=%h period=%h wcet=%h",
                dut.u_task_table.priority_mem[2],
                dut.u_task_table.type_mem[2],
                dut.u_task_table.pre_mem[2],
                dut.u_task_table.deadline_mem[2],
                dut.u_task_table.period_mem[2],
                dut.u_task_table.wcet_mem[2]);
            $display("fail modify payload decode mismatch");
            $finish(1);
        end

        // Long SLEEP task_id=2 with 32-bit ticks=32'h12345678
        send_cmd(32'h7200_0000);
        if (need_word2 !== 1'b1) begin
            $display("fail sleep did not request second word");
            $finish(1);
        end
        send_word2(32'h1234_5678);
        repeat (4) @(posedge clk);

        if (seen_sq_enqueue == 0 || seen_sq_id !== 4'd2 || seen_sq_counter !== 32'h1234_5678) begin
            $display("debug seen_sq_enqueue=%0d id=%0d counter=%h", seen_sq_enqueue, seen_sq_id, seen_sq_counter);
            $display("fail long sleep counter propagation mismatch");
            $finish(1);
        end

        $display("pass");
        $finish;
    end
endmodule
