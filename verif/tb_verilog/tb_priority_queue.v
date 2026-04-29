`timescale 1ns/1ps
module tb_priority_queue;
    reg clk = 0;
    reg rst_n = 0;
    reg enqueue = 0;
    reg dequeue = 0;
    reg flush = 0;
    reg [3:0] enq_id = 0;
    reg [15:0] enq_key = 0;
    wire [3:0] head_id;
    wire [15:0] head_key;
    wire head_valid;
    wire [4:0] depth;

    priority_queue #(.DEPTH(16), .ID_WIDTH(4), .KEY_WIDTH(16)) dut (
        .clk(clk),
        .rst_n(rst_n),
        .enqueue(enqueue),
        .dequeue(dequeue),
        .flush(flush),
        .enq_id(enq_id),
        .enq_key(enq_key),
        .head_id(head_id),
        .head_key(head_key),
        .head_valid(head_valid),
        .depth(depth)
    );

    always #5 clk = ~clk;

    task do_enq(input [3:0] id, input [15:0] key);
    begin
        enq_id = id;
        enq_key = key;
        enqueue = 1;
        @(posedge clk);
        enqueue = 0;
        @(posedge clk);
    end
    endtask

    task check_queue_invariant;
        integer i;
        reg [15:0] key_i, key_next;
        begin
            // dut.dbg_cell_valid and dut.dbg_cell_key are packed vectors:
            // valid bit i  -> dut.dbg_cell_valid[i]
            // key for slot i -> dut.dbg_cell_key[16*i +: 16]
            for (i = 0; i < dut.depth - 1; i = i + 1) begin
                if (dut.dbg_cell_valid[i] !== 1'b1 || dut.dbg_cell_valid[i+1] !== 1'b1) begin
                    $display("fail valid packing broken at %0d", i);
                    $finish(1);
                end
                key_i    = dut.dbg_cell_key[16*i     +: 16];
                key_next = dut.dbg_cell_key[16*(i+1) +: 16];
                if (key_i < key_next) begin
                    $display("fail key order broken at %0d: key[%0d]=%0d < key[%0d]=%0d",
                             i, i, key_i, i+1, key_next);
                    $finish(1);
                end
            end
            for (i = dut.depth; i < 16; i = i + 1) begin
                if (dut.dbg_cell_valid[i] !== 1'b0) begin
                    $display("fail tail valid bit set at %0d", i);
                    $finish(1);
                end
            end
        end
    endtask

    initial begin
        $dumpfile("tb_priority_queue.vcd");
        $dumpvars(0, tb_priority_queue);

        repeat (3) @(posedge clk);
        rst_n = 1;
        @(posedge clk);

        do_enq(4'd1, 16'd10);
        check_queue_invariant();
        do_enq(4'd2, 16'd30);
        check_queue_invariant();
        do_enq(4'd3, 16'd20);
        check_queue_invariant();

        if (head_id !== 4'd2) begin
            $display("fail head expected 2 got %0d", head_id);
            $finish(1);
        end

        dequeue = 1;
        @(posedge clk);
        dequeue = 0;
        @(posedge clk);
        check_queue_invariant();
        if (head_id !== 4'd3) begin
            $display("fail head expected 3 got %0d", head_id);
            $finish(1);
        end

        // same-cycle dequeue+enqueue should keep net depth stable and preserve ordering
        enq_id = 4'd4;
        enq_key = 16'd15;
        enqueue = 1;
        dequeue = 1;
        @(posedge clk);
        enqueue = 0;
        dequeue = 0;
        @(posedge clk);
        check_queue_invariant();
        if (depth !== 2) begin
            $display("fail simultaneous enq/deq depth expected 2 got %0d", depth);
            $finish(1);
        end
        if (head_id !== 4'd4) begin
            $display("fail simultaneous enq/deq head expected 4 got %0d", head_id);
            $finish(1);
        end

        $display("pass");
        $finish;
    end
endmodule
