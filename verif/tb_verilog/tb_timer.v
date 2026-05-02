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

        // !enable path: counter reloads to tick_divider each cycle, no pulses.
        enable = 0;
        repeat (4) @(posedge clk);
        if (tick_counter !== tick_divider || tick_pulse !== 1'b0) begin
            $display("fail enable off hold");
            $finish(1);
        end
        enable = 1;
        repeat (25) begin
            @(posedge clk);
            if (tick_pulse) pulses = pulses + 1;
        end
        if (pulses < 6) begin
            $display("fail pulses after re-enable");
            $finish(1);
        end

        // Asynchronous reset pulse (negedge rst_n) then resume counting.
        enable = 0;
        @(posedge clk);
        rst_n = 0;
        repeat (2) @(posedge clk);
        if (tick_pulse !== 1'b0 || tick_counter !== 16'd0) begin
            $display("fail timer in reset");
            $finish(1);
        end
        rst_n = 1;
        enable = 1;
        repeat (12) begin
            @(posedge clk);
            if (tick_pulse) pulses = pulses + 1;
        end

        $display("pass");
        $finish;
    end
endmodule
