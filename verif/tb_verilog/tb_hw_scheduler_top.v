`timescale 1ns/1ps
// Smoke-test for hw_scheduler_top with the new UART-to-APB front-end.
// Drives raw UART bytes into the chip, lets the vendored uart_apb_master
// translate them into APB transactions against harts_apb_slave, and checks
// that the control_unit's response register reflects each command.
module tb_hw_scheduler_top;
    // Match vendor/uart_apb_master/tb/uart_apb_master_tb.v (16 MHz, DIVISOR=3).
    localparam real CLK_PERIOD = 62.5;
    localparam DIVISOR = 3;
    localparam real BIT_PERIOD = DIVISOR * 16 * CLK_PERIOD;

    // APB offsets (must match rtl/harts_apb_slave.v)
    localparam [31:0] ADDR_CMD_W1 = 32'h0000_0000;
    localparam [31:0] ADDR_CMD_W2 = 32'h0000_0004;
    localparam [31:0] ADDR_RSP = 32'h0000_0008;
    localparam [31:0] ADDR_STATUS = 32'h0000_000C;
    localparam [31:0] ADDR_IRQ_REASON = 32'h0000_0010;

    reg clk;
    reg rst_n = 0;
    reg uart_rx = 1'b1;
    wire uart_tx;
    reg [7:0] ext_irq = 0;
    wire irq_n;
    reg scan_en = 0;
    reg scan_in = 0;
    wire scan_out;

    hw_scheduler_top #(
        .UART_DIVISOR(DIVISOR)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .uart_rx(uart_rx),
        .uart_tx(uart_tx),
        .ext_irq(ext_irq),
        .irq_n(irq_n),
        .scan_en(scan_en),
        .scan_in(scan_in),
        .scan_out(scan_out)
    );

    initial clk = 0;
    always #(CLK_PERIOD / 2.0) clk = ~clk;

    // UART + bridge framing (same as vendor/uart_apb_master_tb.v)
    task uart_send_byte(input [7:0] byte_val);
        integer i;
        begin
            uart_rx = 1'b0;
            #(BIT_PERIOD);
            for (i = 0; i < 8; i = i + 1) begin
                uart_rx = byte_val[i];
                #(BIT_PERIOD);
            end
            uart_rx = 1'b1;
            #(BIT_PERIOD);
        end
    endtask

    task uart_recv_byte(output [7:0] byte_val);
        integer i;
        begin
            @(negedge uart_tx);
            #(BIT_PERIOD / 2);
            #(BIT_PERIOD);
            for (i = 0; i < 8; i = i + 1) begin
                byte_val[i] = uart_tx;
                if (i < 7) #(BIT_PERIOD);
            end
            #(BIT_PERIOD);
        end
    endtask

    task send_write_cmd(input [31:0] addr, input [31:0] data);
        begin
            uart_send_byte(8'hDE);
            uart_send_byte(8'hAD);
            uart_send_byte(8'hA5);
            uart_send_byte(addr[31:24]);
            uart_send_byte(addr[23:16]);
            uart_send_byte(addr[15:8]);
            uart_send_byte(addr[7:0]);
            uart_send_byte(data[31:24]);
            uart_send_byte(data[23:16]);
            uart_send_byte(data[15:8]);
            uart_send_byte(data[7:0]);
        end
    endtask

    task send_read_cmd(input [31:0] addr);
        begin
            uart_send_byte(8'hDE);
            uart_send_byte(8'hAD);
            uart_send_byte(8'h5A);
            uart_send_byte(addr[31:24]);
            uart_send_byte(addr[23:16]);
            uart_send_byte(addr[15:8]);
            uart_send_byte(addr[7:0]);
        end
    endtask

    task recv_write_resp(output [7:0] status);
        uart_recv_byte(status);
    endtask

    task recv_read_resp(output [31:0] data, output [7:0] status);
        reg [7:0] b0, b1, b2, b3;
        begin
            uart_recv_byte(status);
            if (status == 8'hAC) begin
                uart_recv_byte(b0);
                uart_recv_byte(b1);
                uart_recv_byte(b2);
                uart_recv_byte(b3);
                data = {b0, b1, b2, b3};
            end else
                data = 32'hDEAD_DEAD;
        end
    endtask

    task bridge_write32(input [31:0] addr, input [31:0] data);
        reg [7:0] status;
        begin
            fork
                send_write_cmd(addr, data);
                recv_write_resp(status);
            join
            if (status !== 8'hAC) begin
                $display("fail bridge_write32 addr=%h data=%h status=%h", addr, data, status);
                $finish(1);
            end
        end
    endtask

    task bridge_read32(input [31:0] addr, output [31:0] data);
        reg [7:0] status;
        begin
            fork
                send_read_cmd(addr);
                recv_read_resp(data, status);
            join
            if (status !== 8'hAC) begin
                $display("fail bridge_read32 addr=%h status=%h", addr, status);
                $finish(1);
            end
        end
    endtask

    task wait_irq_assert(output reg seen);
        integer i;
        begin
            seen = 0;
            for (i = 0; i < 64; i = i + 1) begin
                @(posedge clk);
                if (irq_n === 1'b0) begin
                    seen = 1;
                    i = 64;
                end
            end
        end
    endtask

    // Continuous sanity checks (lifted from the original SPI testbench)
    always @(posedge clk) begin
        if (rst_n) begin
            if (^irq_n === 1'bx) begin
                $display("fail irq unknown at runtime");
                $finish(1);
            end

            if (dut.u_ctrl.pending_word2 && dut.u_ctrl.cmd_word2_valid) begin
                if (dut.u_ctrl.pending_opcode !== 4'h4 &&
                    dut.u_ctrl.pending_opcode !== 4'h6 &&
                    dut.u_ctrl.pending_opcode !== 4'h7) begin
                    $display("fail pending second word opcode invalid");
                    $finish(1);
                end
            end
        end
    end

    integer i_warmup;
    reg [31:0] rd;

    initial begin
        $dumpfile("verif/sim/tb_hw_scheduler_top.vcd");
        $dumpvars(0, tb_hw_scheduler_top);
        repeat (16) @(posedge clk);
        rst_n = 1;
        // Idle line briefly so the bridge cmd_parser is settled in S_SYNC0.
        for (i_warmup = 0; i_warmup < 4; i_warmup = i_warmup + 1)
            #(BIT_PERIOD);

        // CONFIG: fast_mask=0xFF, sched_mode=RM, tick_div=1, flags=0x80
        bridge_write32(ADDR_CMD_W1, 32'h1063_0180);
        if (dut.u_ctrl.rsp_word !== 32'h0000_c001) begin
            $display("fail CONFIG response: got %h", dut.u_ctrl.rsp_word);
            $finish(1);
        end

        // RUN
        bridge_write32(ADDR_CMD_W1, 32'h2000_0000);
        if (dut.u_ctrl.rsp_word !== 32'h0000_c002) begin
            $display("fail RUN response: got %h", dut.u_ctrl.rsp_word);
            $finish(1);
        end

        // CREATE task_id=1 (two-word command)
        bridge_write32(ADDR_CMD_W1, 32'h410a_0300);
        bridge_write32(ADDR_CMD_W2, 32'h03e8_0064);
        if (dut.u_ctrl.rsp_word !== 32'h0000_c004) begin
            $display("fail CREATE response: got %h", dut.u_ctrl.rsp_word);
            $finish(1);
        end

        // ACTIVATE (empty PQ: c00c or dead_0003)
        bridge_write32(ADDR_CMD_W1, 32'hc100_0000);
        if (dut.u_ctrl.rsp_word !== 32'h0000_c00c &&
            dut.u_ctrl.rsp_word !== 32'hdead_0003) begin
            $display("fail ACTIVATE response: expected c00c or dead_0003, got %h",
                     dut.u_ctrl.rsp_word);
            $finish(1);
        end

        // SLEEP (two-word)
        bridge_write32(ADDR_CMD_W1, 32'h7100_0000);
        bridge_write32(ADDR_CMD_W2, 32'h0000_0064);
        if (dut.u_ctrl.rsp_word !== 32'h0000_c007) begin
            $display("fail SLEEP response: got %h", dut.u_ctrl.rsp_word);
            $finish(1);
        end

        // Read RSP back through the bridge (exercises the read path too).
        bridge_read32(ADDR_RSP, rd);
        if (rd !== 32'h0000_c007) begin
            $display("fail bridge read RSP: got %h", rd);
            $finish(1);
        end

        // External IRQ path
        ext_irq[2] = 1'b1;
        begin : wait_ext_irq
            reg seen_ext_irq;
            wait_irq_assert(seen_ext_irq);
            if (seen_ext_irq !== 1'b1) begin
                $display("fail external irq did not assert irq_n");
                $finish(1);
            end
        end
        // Confirm STATUS register reflects the irq before clearing it.
        bridge_read32(ADDR_STATUS, rd);
        if (rd[0] !== 1'b1) begin
            $display("fail STATUS irq bit not set: got %h", rd);
            $finish(1);
        end
        ext_irq[2] = 1'b0;
        // Send any command — control_unit deasserts irq_n on the next cmd_valid.
        bridge_write32(ADDR_CMD_W1, 32'h0000_0005);
        repeat (40) @(posedge clk);
        if (irq_n !== 1'b1 && irq_n !== 1'b0) begin
            $display("fail irq unknown");
            $finish(1);
        end

        // Scan chain: load parallel state then shift out 256 bits; verify no X
        begin : scan_test
            integer sc_i;
            scan_en = 0;
            @(posedge clk);                // latch parallel_in into scan_reg
            scan_en = 1;
            for (sc_i = 0; sc_i < 256; sc_i = sc_i + 1) begin
                @(posedge clk);
                if (^scan_out === 1'bx) begin
                    $display("fail scan chain X at bit %0d", sc_i);
                    $finish(1);
                end
            end
            scan_en = 0;
        end

        $display("pass");
        $finish;
    end
endmodule
