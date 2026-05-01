`timescale 1ns/1ps
// Full-chip TB for hw_scheduler_top (SPI + timer + PQ + sleep Q + IRQ + scan)

module tb_hw_scheduler_top;
    localparam real TCLK = 10.0; // 100 MHz system clock

    reg clk;
    reg rst_n;
    reg sclk;
    reg cs_n;
    reg mosi;
    wire miso;
    reg [7:0] ext_irq;
    wire irq_n;
    reg scan_en;
    reg scan_in;
    wire scan_out;

    integer failures;

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

    always #(TCLK / 2.0) clk = ~clk;

    // Normalize MISO packing (sample phase vs MSB-first shift-out order)
    function automatic [31:0] spi_miso_rev32(input [31:0] x);
        integer ri;
        begin
            for (ri = 0; ri < 32; ri = ri + 1)
                spi_miso_rev32[ri] = x[31 - ri];
        end
    endfunction

    task automatic spi_idle;
        begin
            @(posedge clk);
            cs_n   = 1'b1;
            sclk   = 1'b0;
            mosi   = 1'b0;
            ext_irq = 8'd0;
            scan_en = 1'b0;
            scan_in = 1'b0;
            repeat (4) @(posedge clk);
        end
    endtask

    // Drive MOSI/SCLK on negedge clk so each posedge sees stable inputs (the SPI slave registers sclk on posedge and detects edges vs sclk_d)
    task automatic spi_xfer32;
        input [31:0] mosi_word;
        output [31:0] miso_word;
        integer bit_idx;
        begin
            @(negedge clk);
            cs_n = 1'b0;
            sclk = 1'b0;
            @(posedge clk);
            miso_word = 32'd0;
            for (bit_idx = 31; bit_idx >= 0; bit_idx = bit_idx - 1) begin
                @(negedge clk);
                mosi = mosi_word[bit_idx];
                sclk = 1'b0;
                @(posedge clk);
                @(negedge clk);
                sclk = 1'b1;
                @(posedge clk);
                @(negedge clk);
                sclk = 1'b0;
                @(posedge clk);
                @(posedge clk);
                miso_word = {miso, miso_word[31:1]};
            end
            @(negedge clk);
            cs_n = 1'b1;
            sclk = 1'b0;
            mosi = 1'b0;
            repeat (10) @(posedge clk);
            miso_word = spi_miso_rev32(miso_word);
        end
    endtask

    task automatic expect_eq;
        input [511:0] msg;
        input [31:0] got;
        input [31:0] exp;
        begin
            if (got !== exp) begin
                $display("FAIL: %s got=%h exp=%h", msg, got, exp);
                failures = failures + 1;
            end else begin
                $display("PASS: %s == %h", msg, got);
            end
        end
    endtask

    initial begin
        $dumpfile("tb_hw_scheduler_top.vcd");
        $dumpvars(0, tb_hw_scheduler_top);

        failures = 0;
        clk      = 1'b0;
        rst_n    = 1'b0;
        sclk     = 1'b0;
        cs_n     = 1'b1;
        mosi     = 1'b0;
        ext_irq  = 8'd0;
        scan_en  = 1'b0;
        scan_in  = 1'b0;

        repeat (8) @(posedge clk);
        rst_n = 1'b1;
        repeat (8) @(posedge clk);

        begin : spi_stimulus
            reg [31:0] r_prev;
            reg [3:0] head_before_activate;

            // rsp shifted out during xfer N is the rsp_word captured at cs_fall(N)
            // (i.e. the completion status for xfer N-1).

            spi_xfer32(32'h0000_0000, r_prev);
            expect_eq("warmup xfer (NOP rsp)", r_prev, 32'h0000_0000);

            spi_xfer32(32'hF0AD_0000, r_prev);
            expect_eq("NOP rsp", r_prev, 32'h0000_0000);

            // CONFIG: [31:20]=0x1ff -> opcode 1 + fast_mask ff; [23:16]=0 -> sched 2'b00;
            // tick_divider[7:0] from [15:8]=4, flags=0
            spi_xfer32(32'h1FF0_0400, r_prev);
            expect_eq("RESET rsp", r_prev, 32'h0000_C0FF);

            // OP_RUN = 4'h2
            spi_xfer32(32'h2000_0000, r_prev);
            expect_eq("CONFIG rsp", r_prev, 32'h0000_C001);

            // CREATE task 0: pri=5 ([23:20]), deadline=0x10, period=0x20, wcet=0x08
            spi_xfer32(32'h4050_0010, r_prev);
            expect_eq("RUN rsp", r_prev, 32'h0000_C002);

            spi_xfer32(32'h0020_0008, r_prev);
            expect_eq("CREATE task0 word1 (rsp still RUN ack)", r_prev, 32'h0000_C002);

            spi_xfer32(32'h0000_0000, r_prev);
            expect_eq("CREATE task0 complete", r_prev, 32'h0000_C004);

            // CREATE task 1: pri=9 (wins ACTIVATE under sched_mode 00)
            spi_xfer32(32'h4190_0010, r_prev);
            expect_eq("NOP after CREATE0", r_prev, 32'h0000_0000);

            spi_xfer32(32'h0020_0008, r_prev);
            expect_eq("CREATE task1 word1", r_prev, 32'h0000_0000);

            spi_xfer32(32'h0000_0000, r_prev);
            expect_eq("CREATE task1 complete", r_prev, 32'h0000_C004);

            // QUERY pq_depth: subcode in [23:16] == 8'h02 -> 2<<16
            spi_xfer32(32'hD002_0000, r_prev);
            expect_eq("NOP after CREATE1", r_prev, 32'h0000_0000);

            spi_xfer32(32'h0000_0000, r_prev);
            expect_eq("pq_depth suspended", r_prev, 32'h0000_0000);

            // RESUME task 0 then 1 -> ready queue
            spi_xfer32(32'hB000_0000, r_prev);
            expect_eq("NOP after QUERY pq", r_prev, 32'h0000_0000);

            spi_xfer32(32'h0000_0000, r_prev);
            expect_eq("RESUME task0", r_prev, 32'h0000_C00B);

            spi_xfer32(32'hB010_0000, r_prev);
            expect_eq("NOP after RESUME0", r_prev, 32'h0000_0000);

            spi_xfer32(32'h0000_0000, r_prev);
            expect_eq("RESUME task1", r_prev, 32'h0000_C00B);

            spi_xfer32(32'hD002_0000, r_prev);
            expect_eq("NOP after RESUME1", r_prev, 32'h0000_0000);

            spi_xfer32(32'h0000_0000, r_prev);
            expect_eq("pq_depth==2", r_prev, 32'h0000_0002);

            // Snapshot PQ head; ACTIVATE must run exactly that task (priority vs. tie
            // order is RTL-defined — this check stays correct regardless).
            repeat (2) @(posedge clk);
            head_before_activate = dut.pq_head_id;

            // ACTIVATE then read current_task via QUERY
            spi_xfer32(32'hC000_0000, r_prev);
            expect_eq("NOP after pq_depth", r_prev, 32'h0000_0000);

            // QUERY current_task: [23:16] == 8'h01
            spi_xfer32(32'hD001_0000, r_prev);
            expect_eq("ACTIVATE rsp", r_prev, 32'h0000_C00C);

            spi_xfer32(32'h0000_0000, r_prev);
            expect_eq("QUERY current_task == pq head before ACTIVATE", r_prev,
                      {28'd0, head_before_activate});

            // QUERY status for whichever task became RUNNING (3'b011)
            spi_xfer32({4'hD, head_before_activate, 8'h00, 16'h0000}, r_prev);
            expect_eq("NOP after QUERY current", r_prev, 32'h0000_0000);

            spi_xfer32(32'h0000_0000, r_prev);
            expect_eq("QUERY status running (3'b011)", r_prev, 32'h0000_0003);

            // OP_STOP = 4'h3
            spi_xfer32(32'h3000_0000, r_prev);
            expect_eq("NOP after QUERY status", r_prev, 32'h0000_0000);

            spi_xfer32(32'h0000_0000, r_prev);
            expect_eq("STOP rsp", r_prev, 32'h0000_C003);

            // RESET then ACTIVATE on empty PQ -> DEAD_0003
            spi_xfer32(32'hF0AD_0000, r_prev);
            expect_eq("NOP after STOP", r_prev, 32'h0000_0000);

            spi_xfer32(32'hC000_0000, r_prev);
            expect_eq("second RESET rsp", r_prev, 32'h0000_C0FF);

            spi_xfer32(32'h0000_0000, r_prev);
            expect_eq("ACTIVATE empty pq rsp", r_prev, 32'hDEAD_0003);
        end

        if (failures != 0) begin
            $display("TEST FAIL: %0d assertion(s)", failures);
            $fatal(1);
        end
        $display("TEST PASS: tb_hw_scheduler_top (see tb_hw_scheduler_top.vcd)");
        #(TCLK * 20);
        $finish;
    end
endmodule
