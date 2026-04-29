`timescale 1ns/1ps
module tb_sleep_queue;
    reg clk = 0;
    reg rst_n = 0;
    reg flush = 0;
    reg enqueue = 0;
    reg tick = 0;
    reg [3:0] enq_id = 0;
    reg [31:0] enq_count = 0;
    wire wake_valid;
    wire [3:0] wake_id;
    wire [4:0] depth;
    integer wakes;
    reg [3:0] first_wake;
    reg [3:0] second_wake;
    reg [4:0] prev_depth;

    sleep_queue #(.DEPTH(16), .ID_WIDTH(4), .CNT_WIDTH(32)) dut (
        .clk(clk),
        .rst_n(rst_n),
        .flush(flush),
        .enqueue(enqueue),
        .tick(tick),
        .enq_id(enq_id),
        .enq_count(enq_count),
        .wake_valid(wake_valid),
        .wake_id(wake_id),
        .depth(depth)
    );

    always #5 clk = ~clk;

    always @(posedge clk) begin
        if (rst_n) begin
            if (^wake_valid === 1'bx || ^wake_id === 1'bx || ^depth === 1'bx) begin
                $display("fail unknown state in sleep queue outputs");
                $finish(1);
            end
            if (depth > 16) begin
                $display("fail sleep queue depth overflow");
                $finish(1);
            end
            if (wake_valid && depth > prev_depth) begin
                $display("fail wake asserted while depth increased");
                $finish(1);
            end
            prev_depth <= depth;
        end
    end

    task do_enq(input [3:0] id, input [15:0] count);
    begin
        enq_id = id;
        enq_count = count;
        enqueue = 1;
        @(posedge clk);
        enqueue = 0;
        @(posedge clk);
    end
    endtask

    task do_tick;
    begin
        tick = 1;
        @(posedge clk);
        if (wake_valid) begin
            wakes = wakes + 1;
            if (wakes == 1) first_wake = wake_id;
            if (wakes == 2) second_wake = wake_id;
        end
        tick = 0;
        @(posedge clk);
    end
    endtask

    initial begin
        $dumpfile("tb_sleep_queue.vcd");
        $dumpvars(0, tb_sleep_queue);
        wakes = 0;
        first_wake = 0;
        second_wake = 0;
        prev_depth = 0;
        repeat (3) @(posedge clk);
        rst_n = 1;
        @(posedge clk);

        do_enq(4'd1, 16'd3);
        do_enq(4'd2, 16'd1);

        // same-cycle tick+enqueue should be deterministic and keep queue coherent
        enq_id = 4'd3;
        enq_count = 16'd2;
        enqueue = 1;
        tick = 1;
        @(posedge clk);
        enqueue = 0;
        tick = 0;
        @(posedge clk);
        if (depth == 0) begin
            $display("fail simultaneous tick+enqueue emptied queue unexpectedly");
            $finish(1);
        end

        // reset queue state so baseline wake-order check remains deterministic
        flush = 1;
        @(posedge clk);
        flush = 0;
        @(posedge clk);
        wakes = 0;
        first_wake = 0;
        second_wake = 0;

        do_enq(4'd1, 16'd3);
        do_enq(4'd2, 16'd1);

        do_tick();
        do_tick();
        do_tick();
        if (!(wakes == 2 && first_wake == 4'd2 && second_wake == 4'd1)) begin
            $display("debug wakes=%0d first=%0d second=%0d", wakes, first_wake, second_wake);
            $display("fail wake sequence expected 2 then 1");
            $finish(1);
        end

        // Multi-expiry: two tasks with the same countdown expire on the same tick.
        // The first wakes on the tick cycle; the second wakes the very next cycle
        // without needing another tick (step-2 runs every cycle when cnt[0]==0).
        begin : multi_expiry
            integer me_wakes;
            reg [3:0] me_first, me_second;
            me_wakes  = 0;
            me_first  = 0;
            me_second = 0;

            flush = 1; @(posedge clk); flush = 0; @(posedge clk);
            do_enq(4'd4, 16'd1);
            do_enq(4'd5, 16'd1);

            // one tick expires both entries simultaneously
            tick = 1; @(posedge clk);
            if (wake_valid) begin me_wakes = me_wakes + 1; me_first = wake_id; end
            tick = 0; @(posedge clk);
            // second entry still has cnt=0; fires without another tick
            if (wake_valid) begin me_wakes = me_wakes + 1; me_second = wake_id; end
            @(posedge clk);

            if (me_wakes !== 2 || me_first !== 4'd4 || me_second !== 4'd5) begin
                $display("fail multi-expiry: wakes=%0d first=%0d second=%0d",
                         me_wakes, me_first, me_second);
                $finish(1);
            end
            if (depth !== 0) begin
                $display("fail multi-expiry: depth=%0d after both wakes", depth);
                $finish(1);
            end
        end

        $display("pass");
        $finish;
    end
endmodule
