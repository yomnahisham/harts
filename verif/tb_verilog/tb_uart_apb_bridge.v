`timescale 1ns/1ps
// Focused test for the new front-end: vendored uart_apb_master bridge in
// front of harts_apb_slave, instantiated through the full hw_scheduler_top.
//
// UART bit timing matches vendor/uart_apb_master/tb/uart_apb_master_tb.v (16 MHz, DIVISOR=3).
//
// Coverage:
//   - WRITE32(CMD_W1) / READ32(RSP) / STATUS / IRQ_REASON
//   - two-word CREATE + pending_word2 in STATUS
//   - unmapped APB -> PSLVERR -> bridge 0xEE
//   - ext_irq → STATUS irq bit + IRQ_REASON
module tb_uart_apb_bridge;
    localparam real CLK_PERIOD = 62.5;
    localparam DIVISOR = 3;
    localparam real BIT_PERIOD = DIVISOR * 16 * CLK_PERIOD;

    localparam [31:0] ADDR_CMD_W1 = 32'h0000_0000;
    localparam [31:0] ADDR_CMD_W2 = 32'h0000_0004;
    localparam [31:0] ADDR_RSP = 32'h0000_0008;
    localparam [31:0] ADDR_STATUS = 32'h0000_000C;
    localparam [31:0] ADDR_IRQ_REASON = 32'h0000_0010;
    localparam [31:0] ADDR_BAD = 32'h0000_0040;

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

    // UART byte tasks (same as vendor tb/uart_apb_master_tb.v)
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

    task bridge_write32(input [31:0] addr, input [31:0] data, output [7:0] status);
        fork
            send_write_cmd(addr, data);
            recv_write_resp(status);
        join
    endtask

    task bridge_read32(input [31:0] addr, output [31:0] data, output [7:0] status);
        fork
            send_read_cmd(addr);
            recv_read_resp(data, status);
        join
    endtask

    task check(input [255:0] name, input cond, input [7:0] s_dbg, input [31:0] rd_dbg);
        begin
            if (cond)
                $display("PASS: %s", name);
            else begin
                $display("FAIL: %s (s=%h rd=%h)", name, s_dbg, rd_dbg);
                failures = failures + 1;
            end
        end
    endtask

    integer i_idle;
    reg [7:0] s;
    reg [31:0] rd;

    initial begin
        $dumpfile("verif/sim/tb_uart_apb_bridge.vcd");
        $dumpvars(0, tb_uart_apb_bridge);

        failures = 0;
        uart_rx = 1'b1;
        rst_n = 1'b0;
        repeat (16) @(posedge clk);
        rst_n = 1'b1;
        for (i_idle = 0; i_idle < 4; i_idle = i_idle + 1)
            #(BIT_PERIOD);

        // Test 1: NOP -> ACK
        bridge_write32(ADDR_CMD_W1, 32'h0000_0000, s);
        check("WRITE32(CMD_W1, NOP) ACK", s == 8'hAC, s, rd);

        // Test 2: RSP read
        bridge_read32(ADDR_RSP, rd, s);
        check("READ32(RSP) ACK after NOP", s == 8'hAC, s, rd);
        check("RSP == 0 after NOP", rd == 32'h0000_0000, s, rd);

        // Test 3: CONFIG
        bridge_write32(ADDR_CMD_W1, 32'h1FF0_0400, s);
        check("CONFIG ACK", s == 8'hAC, s, rd);
        bridge_read32(ADDR_RSP, rd, s);
        check("CONFIG rsp == 0xC001", s == 8'hAC && rd == 32'h0000_C001, s, rd);

        // Test 4: CREATE two-word + STATUS pending_word2
        bridge_write32(ADDR_CMD_W1, 32'h4050_0010, s);
        check("CREATE W1 ACK", s == 8'hAC, s, rd);
        bridge_read32(ADDR_STATUS, rd, s);
        check("STATUS pending_word2 set", s == 8'hAC && rd[1] == 1'b1, s, rd);

        bridge_write32(ADDR_CMD_W2, 32'h0020_0008, s);
        check("CREATE W2 ACK", s == 8'hAC, s, rd);
        bridge_read32(ADDR_STATUS, rd, s);
        check("STATUS pending_word2 cleared", s == 8'hAC && rd[1] == 1'b0, s, rd);
        bridge_read32(ADDR_RSP, rd, s);
        check("CREATE rsp == 0xC004", s == 8'hAC && rd == 32'h0000_C004, s, rd);

        // Test 5/6: unmapped APB -> 0xEE
        bridge_write32(ADDR_BAD, 32'hCAFE_BABE, s);
        check("WRITE32 unmapped -> 0xEE", s == 8'hEE, s, rd);
        bridge_read32(ADDR_BAD, rd, s);
        check("READ32 unmapped -> 0xEE", s == 8'hEE, s, rd);

        // Test 7: ext_irq
        ext_irq[0] = 1'b1;
        repeat (16) @(posedge clk);
        bridge_read32(ADDR_STATUS, rd, s);
        check("STATUS irq bit set on ext_irq", s == 8'hAC && rd[0] == 1'b1, s, rd);
        bridge_read32(ADDR_IRQ_REASON, rd, s);
        check("IRQ_REASON is 0x05 or 0x06",
              s == 8'hAC && (rd[7:0] == 8'h05 || rd[7:0] == 8'h06), s, rd);
        ext_irq[0] = 1'b0;

        if (failures != 0) begin
            $display("BRIDGE TEST FAIL: %0d assertion(s)", failures);
            $fatal(1);
        end
        $display("pass");
        #(CLK_PERIOD * 20);
        $finish;
    end

    initial begin
        #(BIT_PERIOD * 50000);
        $display("FAIL: tb_uart_apb_bridge watchdog timeout");
        $fatal(1);
    end
endmodule
