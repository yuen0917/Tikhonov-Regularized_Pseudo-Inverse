`timescale 1ns / 1ps
module divider_top_tb ();
    reg                clk;
    reg                rst_n;
    reg                start;
    reg  signed [31:0] divisor_data;
    reg  signed [31:0] dividend_data;

    // result_data: {32-bit signed quotient, 16-bit signed fractional}
    wire signed [47:0] result_data;
    wire               result_valid;

    design_1 u_design_1 (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .divisor_data(divisor_data),
        .dividend_data(dividend_data),
        .result_data(result_data),
        .result_valid(result_valid)
    );

    localparam PERIOD = 10;

    always #(PERIOD/2) clk = ~clk;

    // Test one division: value = dividend / divisor
    // t_expected is {32-bit signed quotient, 16-bit signed fractional}
    // fractional: bit[15] is sign bit, bits[14:0] are 15 fraction bits
    task automatic do_test;
        input signed [31:0]  t_divisor;
        input signed [31:0]  t_dividend;
        input signed [47:0]  t_expected;
        real r_result, r_expected;
        reg  signed [31:0] q_s, q_exp;
        reg  signed [15:0] f_s, f_exp;
    begin
        @(negedge clk);
        divisor_data  <= t_divisor;
        dividend_data <= t_dividend;

        start <= 1'b1;
        @(negedge clk);
        start <= 1'b0;

        wait (result_valid == 1'b1);

        // signed quotient and fractional
        q_s   = result_data[47:16];
        f_s   = result_data[15:0];  // signed 16-bit，bit[15] is sign bit
        q_exp = t_expected[47:16];
        f_exp = t_expected[15:0];  // signed 16-bit，bit[15] is sign bit

        // signed fractional：15 個小數 bit，所以除 2^15
        r_result   = $itor(q_s)   + $itor(f_s)   / 32768.0;
        r_expected = $itor(q_exp) + $itor(f_exp) / 32768.0;

        if (result_data === t_expected) begin
            $display("[%0t] PASS: %0d / %0d",
                     $time, t_dividend, t_divisor);
            $display("  result   = %b (q=%0d, f=%0d) = %0.6f",
                     result_data, q_s,   f_s,   r_result);
            $display("  expected = %b (q=%0d, f=%0d) = %0.6f",
                     t_expected,  q_exp, f_exp, r_expected);
        end else begin
            $display("[%0t] FAIL: %0d / %0d",
                     $time, t_dividend, t_divisor);
            $display("  result   = %b (q=%0d, f=%0d) = %0.6f",
                     result_data, q_s,   f_s,   r_result);
            $display("  expected = %b (q=%0d, f=%0d) = %0.6f",
                     t_expected,  q_exp, f_exp, r_expected);
        end

        @(negedge clk);
    end
    endtask

    initial begin
        clk          = 0;
        rst_n        = 0;
        start        = 0;
        divisor_data = 0;
        dividend_data= 0;

        #(PERIOD*2) rst_n = 1;

        // Test 1: 100 / 5 = 20.0 -> quotient=20, fractional=0
        #(PERIOD*2);
        do_test(32'sd5,   32'sd100, 48'h00000014_0000);

        // Test 2: 7 / 3 ≈ 2.3333 -> quotient=2, fractional≈1/3 -> 0x2AAA (10922)
        do_test(32'sd3,   32'sd7,   48'h00000002_2AAA);

        // Test 3: -50 / 4 = -12.5 -> quotient=-12 (0xFFFF_FFF4), fractional=-0.5 -> 0xC000 (-16384)
        do_test(32'sd4,  -32'sd50,  48'hFFFF_FFF4_C000);

        // Test 4: -9 / -3 = 3.0 -> quotient=3, fractional=0
        do_test(-32'sd3, -32'sd9,   48'h00000003_0000);

        $display("All tests finished");
        $finish;
    end

endmodule