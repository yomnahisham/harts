// HARTS APB3 slave: bridges uart_apb_master to control_unit cmd/rsp
// Replaces spi_slave_if + waiting_word2 in hw_scheduler_top.
//
// Registers (32-bit, PADDR[7:0], upper address bits must be 0):
// 0x00 CMD_W1 (W): pulse cmd_valid, cmd_word=WDATA; if opcode in {4,6,7} set pending_word2
// 0x04 CMD_W2 (W): pulse cmd_word2_valid, cmd_word2=WDATA, clear pending_word2
// 0x08 RSP (R): rsp_word
// 0x0C STATUS (R): {30'd0, pending_word2, ~irq_n}
// 0x10 IRQ_REASON (R): {24'd0, irq_reason}
// PSLVERR on decode miss. PREADY=1 (zero-wait-state)

module harts_apb_slave (
    input wire clk,
    input wire rst_n,
    input wire [31:0] PADDR,
    input wire PSEL,
    input wire PENABLE,
    input wire PWRITE,
    input wire [31:0] PWDATA,
    output reg [31:0] PRDATA,
    output wire PREADY,
    output wire PSLVERR,
    output reg cmd_valid,
    output reg [31:0] cmd_word,
    output reg cmd_word2_valid,
    output reg [31:0] cmd_word2,
    input wire [31:0] rsp_word,
    input wire irq_n,
    input wire [7:0] irq_reason
);
    localparam ADDR_CMD_W1 = 8'h00;
    localparam ADDR_CMD_W2 = 8'h04;
    localparam ADDR_RSP = 8'h08;
    localparam ADDR_STATUS = 8'h0C;
    localparam ADDR_IRQ_REASON = 8'h10;

    wire [7:0] addr_lo = PADDR[7:0];
    wire upper_zero = (PADDR[31:8] == 24'd0);
    wire word_aligned = (PADDR[1:0] == 2'b00);
    wire offset_known =
        (addr_lo == ADDR_CMD_W1) || (addr_lo == ADDR_CMD_W2) || (addr_lo == ADDR_RSP) ||
        (addr_lo == ADDR_STATUS) || (addr_lo == ADDR_IRQ_REASON);
    wire addr_in_map = upper_zero & word_aligned & offset_known;

    wire access = PSEL & PENABLE;
    wire write_phase = access & PWRITE & addr_in_map;

    assign PREADY = 1'b1;
    assign PSLVERR = access & ~addr_in_map;

    reg pending_word2;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cmd_valid <= 1'b0;
            cmd_word <= 32'd0;
            cmd_word2_valid <= 1'b0;
            cmd_word2 <= 32'd0;
            pending_word2 <= 1'b0;
        end else begin
            cmd_valid <= 1'b0;
            cmd_word2_valid <= 1'b0;
            if (write_phase) begin
                case (addr_lo)
                    ADDR_CMD_W1: begin
                        cmd_valid <= 1'b1;
                        cmd_word <= PWDATA;
                        if (PWDATA[31:28] == 4'h4 || PWDATA[31:28] == 4'h6 ||
                            PWDATA[31:28] == 4'h7)
                            pending_word2 <= 1'b1;
                    end
                    ADDR_CMD_W2: begin
                        cmd_word2_valid <= 1'b1;
                        cmd_word2 <= PWDATA;
                        pending_word2 <= 1'b0;
                    end
                    default: ;
                endcase
            end
        end
    end

    always @(*) begin
        case (addr_lo)
            ADDR_RSP: PRDATA = rsp_word;
            ADDR_STATUS: PRDATA = {30'd0, pending_word2, ~irq_n};
            ADDR_IRQ_REASON: PRDATA = {24'd0, irq_reason};
            default: PRDATA = 32'd0;
        endcase
    end
endmodule
