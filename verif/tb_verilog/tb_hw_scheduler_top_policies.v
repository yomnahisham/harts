`timescale 1ns/1ps
// UART+APB integration: scheduling policy ordering on the real priority_queue
// (RM: shorter period at head; EDF: smaller relative deadline field at head).
module tb_hw_scheduler_top_policies;
    localparam real CLK_PERIOD = 62.5;
    localparam DIVISOR = 3;
    localparam real BIT_PERIOD = DIVISOR * 16 * CLK_PERIOD;

    localparam [31:0] ADDR_CMD_W1 = 32'h0000_0000;
    localparam [31:0] ADDR_CMD_W2 = 32'h0000_0004;
    localparam [31:0] ADDR_RSP = 32'h0000_0008;

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
                $display("FAIL policies: bridge_write32 addr=%h status=%h", addr, status);
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
                $display("FAIL policies: bridge_read32 addr=%h status=%h", addr, status);
                failures = failures + 1;
                data = 32'hDEAD_DEAD;
            end
        end
    endtask

    task automatic do_cmd_check(input [255:0] msg,
                                input [31:0] cmd,
                                input [31:0] exp);
        reg [31:0] rd;
        begin
            bridge_write32(ADDR_CMD_W1, cmd);
            bridge_read32(ADDR_RSP, rd);
            if (rd !== exp) begin
                $display("FAIL policies: %s cmd=%h got=%h exp=%h", msg, cmd, rd, exp);
                failures = failures + 1;
            end else
                $display("PASS policies: %s rsp=%h", msg, rd);
        end
    endtask

    task automatic do_cmd2_check(input [255:0] msg,
                                 input [31:0] cmd_w1,
                                 input [31:0] cmd_w2,
                                 input [31:0] exp);
        reg [31:0] rd;
        begin
            bridge_write32(ADDR_CMD_W1, cmd_w1);
            bridge_write32(ADDR_CMD_W2, cmd_w2);
            bridge_read32(ADDR_RSP, rd);
            if (rd !== exp) begin
                $display("FAIL policies: %s got=%h exp=%h", msg, rd, exp);
                failures = failures + 1;
            end else
                $display("PASS policies: %s rsp=%h", msg, rd);
        end
    endtask

    initial begin
        $dumpfile("verif/sim/tb_hw_scheduler_top_policies.vcd");
        $dumpvars(0, tb_hw_scheduler_top_policies);

        failures = 0;
        rst_n = 1'b0;
        uart_rx = 1'b1;
        ext_irq = 8'd0;
        scan_en = 1'b0;
        scan_in = 1'b0;

        repeat (16) @(posedge clk);
        rst_n = 1'b1;
        repeat (4) #(BIT_PERIOD);

        begin
            reg [31:0] rd;
            reg [3:0] head_rm;
            reg [3:0] head_edf;

            // ----- RM: same static priority, shorter period must be PQ head -----
            do_cmd_check("RESET", 32'hF0AD_0000, 32'h0000_C0FF);
            // CONFIG: sched_mode=01 (RM), tick_div=4, fast_mask=0xFF
            do_cmd_check("CONFIG RM", 32'h1FF1_0400, 32'h0000_C001);
            do_cmd_check("RUN", 32'h2000_0000, 32'h0000_C002);
            // Task0 id=0 pri=5 deadline=0x10, period=100, wcet=8
            do_cmd2_check("CREATE t0 long period",
                          32'h4050_0010, 32'h0064_0008, 32'h0000_C004);
            // Task1 id=1 pri=5 deadline=0x10, period=20, wcet=8
            do_cmd2_check("CREATE t1 short period",
                          32'h4150_0010, 32'h0014_0008, 32'h0000_C004);
            do_cmd_check("RESUME t0", 32'hB000_0000, 32'h0000_C00B);
            do_cmd_check("RESUME t1", 32'hB100_0000, 32'h0000_C00B);
            bridge_write32(ADDR_CMD_W1, 32'hD002_0000);
            bridge_read32(ADDR_RSP, rd);
            if (rd !== 32'h0000_0002) begin
                $display("FAIL policies: pq_depth RM got=%h", rd);
                failures = failures + 1;
            end else
                $display("PASS policies: pq_depth==2 (RM)");
            repeat (3) @(posedge clk);
            head_rm = dut.pq_head_id;
            if (head_rm !== 4'd1) begin
                $display("FAIL policies: RM head id got=%0d exp=1", head_rm);
                failures = failures + 1;
            end else
                $display("PASS policies: RM pq head is task 1 (shorter period)");
            do_cmd_check("ACTIVATE RM", 32'hC000_0000, 32'h0000_C00C);
            bridge_write32(ADDR_CMD_W1, 32'hD001_0000);
            bridge_read32(ADDR_RSP, rd);
            if (rd !== {28'd0, 4'd1}) begin
                $display("FAIL policies: QUERY current after RM ACTIVATE got=%h", rd);
                failures = failures + 1;
            end else
                $display("PASS policies: current_task==1 after RM ACTIVATE");

            // ----- EDF: same pri, smaller relative deadline field wins -----
            do_cmd_check("RESET (EDF)", 32'hF0AD_0000, 32'h0000_C0FF);
            // CONFIG: sched_mode=10 (EDF), tick_div=4 — no RUN so tick_count stays 0
            // during UART-heavy CREATE/RESUME (EDF key uses tick_count[15:0]).
            do_cmd_check("CONFIG EDF", 32'h1FF2_0400, 32'h0000_C001);
            // Task0: deadline field 200 (0xC8)
            do_cmd2_check("CREATE t0 long deadline",
                          32'h4050_00C8, 32'h0064_0008, 32'h0000_C004);
            // Task1: deadline field 20 (0x14)
            do_cmd2_check("CREATE t1 short deadline",
                          32'h4150_0014, 32'h0014_0008, 32'h0000_C004);
            do_cmd_check("RESUME t0 EDF", 32'hB000_0000, 32'h0000_C00B);
            do_cmd_check("RESUME t1 EDF", 32'hB100_0000, 32'h0000_C00B);
            bridge_write32(ADDR_CMD_W1, 32'hD002_0000);
            bridge_read32(ADDR_RSP, rd);
            if (rd !== 32'h0000_0002) begin
                $display("FAIL policies: pq_depth EDF got=%h", rd);
                failures = failures + 1;
            end else
                $display("PASS policies: pq_depth==2 (EDF)");
            repeat (3) @(posedge clk);
            head_edf = dut.pq_head_id;
            if (head_edf !== 4'd1) begin
                $display("FAIL policies: EDF head id got=%0d exp=1", head_edf);
                failures = failures + 1;
            end else
                $display("PASS policies: EDF pq head is task 1 (tighter deadline field)");
            do_cmd_check("ACTIVATE EDF", 32'hC000_0000, 32'h0000_C00C);
            bridge_write32(ADDR_CMD_W1, 32'hD001_0000);
            bridge_read32(ADDR_RSP, rd);
            if (rd !== {28'd0, 4'd1}) begin
                $display("FAIL policies: QUERY current after EDF ACTIVATE got=%h", rd);
                failures = failures + 1;
            end else
                $display("PASS policies: current_task==1 after EDF ACTIVATE");
        end

        if (failures != 0) begin
            $display("TEST FAIL policies: %0d errors", failures);
            $fatal(1);
        end
        $display("TEST PASS: tb_hw_scheduler_top_policies");
        // Pulse ext_irq so VCD sanity (top mode) sees a non-zero host interrupt sample.
        ext_irq[0] = 1'b1;
        repeat (8) @(posedge clk);
        ext_irq[0] = 1'b0;
        #(CLK_PERIOD * 20);
        $finish;
    end
endmodule
