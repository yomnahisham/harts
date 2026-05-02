module spi_slave_if (
    input wire clk,
    input wire rst_n,
    input wire sclk,
    input wire cs_n,
    input wire mosi,
    output reg miso,
    output reg cmd_valid,
    output reg [31:0] cmd_word,
    input wire [31:0] rsp_word
);
    reg [31:0] rx_shift;
    reg [31:0] tx_shift;
    reg [5:0] bit_count;
    reg sclk_d;
    reg cs_d;
    wire sclk_rise = (sclk && !sclk_d);
    wire sclk_fall = (!sclk && sclk_d);
    wire cs_fall = (!cs_n && cs_d);
    wire cs_rise = (cs_n && !cs_d);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_shift <= 0;
            tx_shift <= 0;
            cmd_word <= 0;
            cmd_valid <= 0;
            bit_count <= 0;
            miso <= 0;
            sclk_d <= 0;
            cs_d <= 1;
        end else begin
            sclk_d <= sclk;
            cs_d <= cs_n;
            cmd_valid <= 0;

            if (cs_fall) begin
                bit_count <= 0;
                tx_shift <= rsp_word;
            end

            if (!cs_n && sclk_rise) begin
                rx_shift <= {rx_shift[30:0], mosi};
                bit_count <= bit_count + 1'b1;
            end

            if (!cs_n && sclk_fall) begin
                miso <= tx_shift[31];
                tx_shift <= {tx_shift[30:0], 1'b0};
            end

            if (cs_rise && bit_count == 6'd32) begin
                cmd_word <= rx_shift;
                cmd_valid <= 1'b1;
            end
        end
    end
endmodule
