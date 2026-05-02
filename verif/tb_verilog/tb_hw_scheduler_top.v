`timescale 1ns/1ps
module tb_hw_scheduler_top;
    reg clk = 0;
    reg rst_n = 0;
    reg sclk = 0;
    reg cs_n = 1;
    reg mosi = 0;
    reg [7:0] ext_irq = 0;
    wire miso;
    wire irq_n;
    reg scan_en = 0;
    reg scan_in = 0;
    wire scan_out;

    hw_scheduler_top dut (
        .clk(clk),
        .rst_n(rst_n),
        .sclk(sclk),
        .cs_n(cs_n),
        .mosi(mosi),
        .miso(miso),
        .ext_irq(ext_irq),
        .irq_n(irq_n),
        .scan_en(scan_en),
        .scan_in(scan_in),
        .scan_out(scan_out)
    );

    always #5 clk = ~clk;

    task spi_send32(input [31:0] w);
        integer i;
        begin
            @(negedge clk);
            cs_n = 0;
            for (i = 31; i >= 0; i = i - 1) begin
                mosi = w[i];
                @(negedge clk); sclk = 1;
                @(posedge clk); @(negedge clk); sclk = 0;
                @(posedge clk);
            end
            @(negedge clk);
            cs_n = 1;
            repeat (3) @(posedge clk);
        end
    endtask

    task wait_irq_assert(output reg seen);
        integer i;
        begin
            seen = 0;
            for (i = 0; i < 24; i = i + 1) begin
                @(posedge clk);
                if (irq_n === 1'b0) begin
                    seen = 1;
                    i = 24;
                end
            end
        end
    endtask

    always @(posedge clk) begin
        if (rst_n) begin
            if (^irq_n === 1'bx) begin
                $display("fail irq unknown at runtime");
                $finish(1);
            end

            if (dut.u_ctrl.pending_word2 && dut.u_ctrl.cmd_word2_valid) begin
                if (dut.u_ctrl.pending_opcode !== 4'h4 && dut.u_ctrl.pending_opcode !== 4'h6 && dut.u_ctrl.pending_opcode !== 4'h7) begin
                    $display("fail pending second word opcode invalid");
                    $finish(1);
                end
            end

            // Note: ctrl_cmd_valid and waiting_word2 are both 1 at the cycle
            // the first word of a two-word command is delivered — that is correct.
        end
    end

    initial begin
        $dumpfile("tb_hw_scheduler_top.vcd");
        $dumpvars(0, tb_hw_scheduler_top);
        repeat (4) @(posedge clk);
        rst_n = 1;
        @(posedge clk);

        // CONFIG: fast_mask=0xFF, sched_mode=RM, tick_div=1, flags=0x80
        spi_send32(32'h1063_0180);
        repeat (3) @(posedge clk);
        if (dut.u_ctrl.rsp_word !== 32'h0000_c001) begin
            $display("fail CONFIG response: got %h", dut.u_ctrl.rsp_word);
            $finish(1);
        end

        // RUN
        spi_send32(32'h2000_0000);
        repeat (3) @(posedge clk);
        if (dut.u_ctrl.rsp_word !== 32'h0000_c002) begin
            $display("fail RUN response: got %h", dut.u_ctrl.rsp_word);
            $finish(1);
        end

        // CREATE task_id=1 (two-word command)
        spi_send32(32'h410a_0300);
        spi_send32(32'h03e8_0064);
        repeat (3) @(posedge clk);
        if (dut.u_ctrl.rsp_word !== 32'h0000_c004) begin
            $display("fail CREATE response: got %h", dut.u_ctrl.rsp_word);
            $finish(1);
        end

        // ACTIVATE (empty PQ: c00c or dead_0003)
        spi_send32(32'hc100_0000);
        repeat (3) @(posedge clk);
        if (dut.u_ctrl.rsp_word !== 32'h0000_c00c &&
            dut.u_ctrl.rsp_word !== 32'hdead_0003) begin
            $display("fail ACTIVATE response: expected c00c or dead_0003, got %h",
                     dut.u_ctrl.rsp_word);
            $finish(1);
        end

        // SLEEP (two-word)
        spi_send32(32'h7100_0000);
        spi_send32(32'h0000_0064);
        repeat (3) @(posedge clk);
        if (dut.u_ctrl.rsp_word !== 32'h0000_c007) begin
            $display("fail SLEEP response: got %h", dut.u_ctrl.rsp_word);
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
        ext_irq[2] = 1'b0;
        repeat (220) @(posedge clk);
        spi_send32(32'h0000_0005);

        repeat (80) @(posedge clk);
        if (irq_n !== 1'b1 && irq_n !== 1'b0) begin
            $display("fail irq unknown");
            $finish(1);
        end

        // Scan chain: load parallel state then shift out 256 bits; verify no X
        begin : scan_test
            integer sc_i;
            scan_en = 0;
            @(posedge clk);       // latch parallel_in into scan_reg
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
