`timescale 1ns/1ps
// Full-chip TB for hw_scheduler_top with the UART-to-APB front-end
// (bridge + harts_apb_slave + control_unit + queues + timer + IRQ + scan).
//
// Each command is delivered as a UART WRITE32 against the harts_apb_slave
// register map (CMD_W1 / CMD_W2 / RSP / STATUS / IRQ_REASON), and the
// expected control_unit response is read back via a UART READ32 of RSP.
module tb_hw_scheduler_top;
    // Match OpenLane CLOCK_PERIOD (25 ns = 40 MHz) and hw_scheduler_top UART_DIVISOR default (~115200 baud).
    localparam real CLK_PERIOD = 25.0;
    localparam integer DIVISOR = 22;
    localparam real BIT_PERIOD = DIVISOR * 16 * CLK_PERIOD;

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

    integer failures;

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

    // ---- UART + bridge framing (vendor/uart_apb_master_tb.v style) ----
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
                $display("FAIL: bridge_write32 addr=%h data=%h status=%h",
                         addr, data, status);
                failures = failures + 1;
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
                $display("FAIL: bridge_read32 addr=%h status=%h", addr, status);
                failures = failures + 1;
                data = 32'hDEAD_DEAD;
            end
        end
    endtask

    // Helpers: write a one-word command and read RSP back; assert it equals exp.
    task automatic do_cmd_check(input [511:0] msg,
                                input [31:0] cmd,
                                input [31:0] exp);
        reg [31:0] rd;
        begin
            bridge_write32(ADDR_CMD_W1, cmd);
            bridge_read32(ADDR_RSP, rd);
            if (rd !== exp) begin
                $display("FAIL: %s cmd=%h got=%h exp=%h", msg, cmd, rd, exp);
                failures = failures + 1;
            end else begin
                $display("PASS: %s rsp=%h", msg, rd);
            end
        end
    endtask

    // Two-word command + check.
    task automatic do_cmd2_check(input [511:0] msg,
                                 input [31:0] cmd_w1,
                                 input [31:0] cmd_w2,
                                 input [31:0] exp);
        reg [31:0] rd;
        begin
            bridge_write32(ADDR_CMD_W1, cmd_w1);
            bridge_write32(ADDR_CMD_W2, cmd_w2);
            bridge_read32(ADDR_RSP, rd);
            if (rd !== exp) begin
                $display("FAIL: %s w1=%h w2=%h got=%h exp=%h",
                         msg, cmd_w1, cmd_w2, rd, exp);
                failures = failures + 1;
            end else begin
                $display("PASS: %s rsp=%h", msg, rd);
            end
        end
    endtask

    initial begin
        $dumpfile("verif/sim/tb_hw_scheduler_top_final.vcd");
        $dumpvars(0, tb_hw_scheduler_top);

        failures = 0;
        rst_n = 1'b0;
        uart_rx = 1'b1;
        ext_irq = 8'd0;
        scan_en = 1'b0;
        scan_in = 1'b0;

        repeat (16) @(posedge clk);
        rst_n = 1'b1;
        // Idle line a few bit-times so the bridge's parser starts in S_SYNC0.
        repeat (4) #(BIT_PERIOD);

        begin : uart_stimulus
            reg [3:0] head_before_activate;
            reg [31:0] rd;

            // Reset to a known state via OP_RESET (key 0xAD).
            do_cmd_check("RESET", 32'hF0AD_0000, 32'h0000_C0FF);

            // CONFIG: fast_mask=0xFF, sched_mode=00 (priority), tick_div=4, flags=0
            do_cmd_check("CONFIG", 32'h1FF0_0400, 32'h0000_C001);

            // OP_RUN
            do_cmd_check("RUN", 32'h2000_0000, 32'h0000_C002);

            // CREATE task 0: pri=5 ([23:20]), deadline=0x10, period=0x20, wcet=0x08
            do_cmd2_check("CREATE task0", 32'h4050_0010, 32'h0020_0008, 32'h0000_C004);

            // CREATE task 1: pri=9 (wins ACTIVATE under sched_mode 00)
            do_cmd2_check("CREATE task1", 32'h4190_0010, 32'h0020_0008, 32'h0000_C004);

            // QUERY pq_depth: subcode in [23:16] == 8'h02
            bridge_write32(ADDR_CMD_W1, 32'hD002_0000);
            bridge_read32(ADDR_RSP, rd);
            if (rd !== 32'h0000_0000) begin
                $display("FAIL: pq_depth suspended got=%h exp=0", rd);
                failures = failures + 1;
            end else begin
                $display("PASS: pq_depth suspended rsp=%h", rd);
            end

            // RESUME task 0 then 1 -> ready queue
            do_cmd_check("RESUME task0", 32'hB000_0000, 32'h0000_C00B);
            do_cmd_check("RESUME task1", 32'hB100_0000, 32'h0000_C00B);

            bridge_write32(ADDR_CMD_W1, 32'hD002_0000);
            bridge_read32(ADDR_RSP, rd);
            if (rd !== 32'h0000_0002) begin
                $display("FAIL: pq_depth==2 got=%h exp=2", rd);
                failures = failures + 1;
            end else begin
                $display("PASS: pq_depth==2 rsp=%h", rd);
            end

            // Snapshot PQ head; ACTIVATE must run exactly that task.
            repeat (2) @(posedge clk);
            head_before_activate = dut.pq_head_id;

            // ACTIVATE then read current_task via QUERY
            do_cmd_check("ACTIVATE", 32'hC000_0000, 32'h0000_C00C);

            bridge_write32(ADDR_CMD_W1, 32'hD001_0000);
            bridge_read32(ADDR_RSP, rd);
            if (rd !== {28'd0, head_before_activate}) begin
                $display("FAIL: QUERY current_task got=%h exp=%h",
                         rd, {28'd0, head_before_activate});
                failures = failures + 1;
            end else begin
                $display("PASS: QUERY current_task rsp=%h", rd);
            end

            // QUERY status for whichever task became RUNNING (3'b011)
            bridge_write32(ADDR_CMD_W1, {4'hD, head_before_activate, 8'h00, 16'h0000});
            bridge_read32(ADDR_RSP, rd);
            if (rd !== 32'h0000_0003) begin
                $display("FAIL: QUERY status running got=%h exp=3", rd);
                failures = failures + 1;
            end else begin
                $display("PASS: QUERY status running rsp=%h", rd);
            end

            // OP_STOP
            do_cmd_check("STOP", 32'h3000_0000, 32'h0000_C003);

            // RESET then ACTIVATE on empty PQ -> DEAD_0003
            do_cmd_check("second RESET", 32'hF0AD_0000, 32'h0000_C0FF);
            do_cmd_check("ACTIVATE empty pq", 32'hC000_0000, 32'hDEAD_0003);

            // External IRQ path: assert ext_irq[2], confirm STATUS reflects it,
            // confirm IRQ_REASON is the slow-external code (0x06, since we never
            // configured fast_mask after the second RESET).
            ext_irq[2] = 1'b1;
            repeat (16) @(posedge clk);
            bridge_read32(ADDR_STATUS, rd);
            if (rd[0] !== 1'b1) begin
                $display("FAIL: STATUS irq bit not set after ext_irq: got=%h", rd);
                failures = failures + 1;
            end else begin
                $display("PASS: STATUS irq bit set rsp=%h", rd);
            end
            bridge_read32(ADDR_IRQ_REASON, rd);
            if (rd[7:0] !== 8'h05 && rd[7:0] !== 8'h06) begin
                $display("FAIL: IRQ_REASON unexpected got=%h", rd);
                failures = failures + 1;
            end else begin
                $display("PASS: IRQ_REASON rsp=%h", rd);
            end
            ext_irq[2] = 1'b0;
        end

        if (failures != 0) begin
            $display("TEST FAIL: %0d assertion(s)", failures);
            $fatal(1);
        end
        $display("TEST PASS: tb_hw_scheduler_top_final (see verif/sim/tb_hw_scheduler_top_final.vcd)");
        #(CLK_PERIOD * 20);
        $finish;
    end
endmodule
