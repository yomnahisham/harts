`timescale 1ns/1ps
module tb_timer;
    reg clk = 0;
    reg rst_n = 0;
    reg enable = 0;
    reg [15:0] tick_divider = 16'd2;
    wire tick_pulse;
    wire [15:0] tick_counter;
    integer pulses;

    timer dut (
        .clk(clk),
        .rst_n(rst_n),
        .enable(enable),
        .tick_divider(tick_divider),
        .tick_pulse(tick_pulse),
        .tick_counter(tick_counter)
    );

    always #5 clk = ~clk;

    always @(posedge clk) begin
        if (rst_n) begin
            if (^tick_pulse === 1'bx || ^tick_counter === 1'bx) begin
                $display("fail unknown timer outputs");
                $finish(1);
            end
            if (tick_pulse && tick_counter !== tick_divider) begin
                $display("fail timer reload mismatch");
                $finish(1);
            end
        end
    end

    initial begin
        pulses = 0;
        repeat (3) @(posedge clk);
        rst_n = 1;
        enable = 1;
        repeat (20) begin
            @(posedge clk);
            if (tick_pulse) pulses = pulses + 1;
        end
        if (pulses < 4) begin
            $display("fail not enough pulses");
            $finish(1);
        end
        $display("pass");
        $finish;
    end
endmodule
