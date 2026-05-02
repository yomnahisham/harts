// SymbiYosys BMC wrapper: timer counter stays bounded when enabled (see timer_bmc.sby).
`default_nettype none
module timer_fv (
    input wire clk
);
    reg        rst_n;
    reg        enable;
    reg [15:0] tick_divider;
    wire       tick_pulse;
    wire [15:0] tick_counter;

    reg [7:0] cycle;

    timer u_timer (
        .clk(clk),
        .rst_n(rst_n),
        .enable(enable),
        .tick_divider(tick_divider),
        .tick_pulse(tick_pulse),
        .tick_counter(tick_counter)
    );

    initial begin
        rst_n = 1'b0;
        enable = 1'b0;
        tick_divider = 16'd2;
        cycle = 8'd0;
    end

    always @(posedge clk) begin
        cycle <= cycle + 8'd1;
        if (cycle == 8'd2)
            rst_n <= 1'b1;
        if (cycle == 8'd5) begin
            enable <= 1'b1;
            tick_divider <= 16'd3;
        end
    end

    always @(*) begin
        assume(tick_divider >= 16'd1 && tick_divider <= 16'd8);
    end

    always @(posedge clk) begin
        if (rst_n && enable)
            assert(tick_counter <= tick_divider);
    end
endmodule

`default_nettype wire
