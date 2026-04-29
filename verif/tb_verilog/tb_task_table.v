`timescale 1ns/1ps
module tb_task_table;
    reg clk = 0;
    reg rst_n = 0;
    reg clear_all = 0;
    reg wr_en = 0;
    reg [3:0] wr_id = 0;
    reg [3:0] wr_priority = 0;
    reg [15:0] wr_period = 0;
    reg [15:0] wr_deadline = 0;
    reg [15:0] wr_wcet = 0;
    reg wr_type = 0;
    reg wr_preemptable = 0;
    reg [2:0] wr_status = 0;
    reg [15:0] wr_abs_deadline = 0;
    reg [15:0] wr_remaining_wcet = 0;
    reg rd_en = 0;
    reg [3:0] rd_id = 0;
    wire [3:0] rd_priority;
    wire [15:0] rd_period;
    wire [15:0] rd_deadline;
    wire [15:0] rd_wcet;
    wire rd_type;
    wire rd_preemptable;
    wire [2:0] rd_status;
    wire [15:0] rd_abs_deadline;
    wire [15:0] rd_remaining_wcet;

    task_table dut (
        .clk(clk),
        .rst_n(rst_n),
        .clear_all(clear_all),
        .wr_en(wr_en),
        .wr_id(wr_id),
        .wr_priority(wr_priority),
        .wr_period(wr_period),
        .wr_deadline(wr_deadline),
        .wr_wcet(wr_wcet),
        .wr_type(wr_type),
        .wr_preemptable(wr_preemptable),
        .wr_status(wr_status),
        .wr_abs_deadline(wr_abs_deadline),
        .wr_remaining_wcet(wr_remaining_wcet),
        .rd_en(rd_en),
        .rd_id(rd_id),
        .rd_priority(rd_priority),
        .rd_period(rd_period),
        .rd_deadline(rd_deadline),
        .rd_wcet(rd_wcet),
        .rd_type(rd_type),
        .rd_preemptable(rd_preemptable),
        .rd_status(rd_status),
        .rd_abs_deadline(rd_abs_deadline),
        .rd_remaining_wcet(rd_remaining_wcet)
    );

    always #5 clk = ~clk;

    always @(posedge clk) begin
        if (rst_n) begin
            if (^rd_priority === 1'bx || ^rd_period === 1'bx || ^rd_status === 1'bx) begin
                $display("fail unknown task table read output");
                $finish(1);
            end
            if (wr_en && wr_id > 4'd15) begin
                $display("fail task table write id out of range");
                $finish(1);
            end
            if (rd_en && rd_id > 4'd15) begin
                $display("fail task table read id out of range");
                $finish(1);
            end
        end
    end

    initial begin
        repeat (3) @(posedge clk);
        rst_n = 1;
        wr_en = 1;
        wr_id = 4'd5;
        wr_priority = 4'd8;
        wr_period = 16'd100;
        wr_deadline = 16'd120;
        wr_wcet = 16'd20;
        wr_type = 1'b1;
        wr_preemptable = 1'b1;
        wr_status = 3'b010;
        wr_abs_deadline = 16'd150;
        wr_remaining_wcet = 16'd20;
        @(posedge clk);
        wr_en = 0;
        rd_en = 1;
        rd_id = 4'd5;
        #1;
        if (rd_priority !== 4'd8 || rd_period !== 16'd100 || rd_status !== 3'b010) begin
            $display("fail task table readback");
            $finish(1);
        end
        $display("pass");
        $finish;
    end
endmodule
