`timescale 1ns / 1ps

module tb;

    reg  [11:0] D;
    wire        S;
    wire [2:0]  E;
    wire [3:0]  F;

    // Instantiate Unit Under Test (UUT)
    FPCVT uut (
        .D(D),
        .S(S),
        .E(E),
        .F(F)
    );

    integer i;
    integer errors = 0;

    // Reference task to verify specific test vectors
    task check_case(
        input [11:0] in_D,
        input        exp_S,
        input [2:0]  exp_E,
        input [3:0]  exp_F,
        input [8*32:1] label
    );
    begin
        D = in_D;
        #10;
        if (S !== exp_S || E !== exp_E || F !== exp_F) begin
            $display("[FAIL] %0s | D=%b (%0d) -> Got S=%b E=%b (%0d) F=%b (%0d) | Expected S=%b E=%b F=%b",
                     label, D, $signed(D), S, E, E, F, F, exp_S, exp_E, exp_F);
            errors = errors + 1;
        end else begin
            $display("[PASS] %0s | D=%b (%0d) -> S=%b E=%b (%0d) F=%b (%0d) (Value = %0d)",
                     label, D, $signed(D), S, E, E, F, F, (S ? -1 : 1) * F * (1 << E));
        end
    end
    endtask

    initial begin
        $display("=== Starting FPCVT Corner Case & Handout Verification ===");

        // 1. Zero & Small Magnitude Denormalized Cases (LZ >= 8, E = 0)
        check_case(12'd0,     1'b0, 3'd0, 4'b0000, "Zero (0)");
        check_case(12'd15,    1'b0, 3'd0, 4'b1111, "Max E=0 (15)");
        check_case(-12'd15,   1'b1, 3'd0, 4'b1111, "Negative E=0 (-15)");

        // 2. Handout Examples (422 and -422)
        check_case(12'd422,   1'b0, 3'd5, 4'b1101, "Handout +422");
        check_case(-12'd422,  1'b1, 3'd5, 4'b1101, "Handout -422");

        // 3. Handout Rounding Table Examples
        check_case(12'b0000_0010_1100, 1'b0, 3'b010, 4'b1011, "Round Down (44)");
        check_case(12'b0000_0010_1101, 1'b0, 3'b010, 4'b1011, "Round Down (45)");
        check_case(12'b0000_0010_1110, 1'b0, 3'b010, 4'b1100, "Round Up (46)");
        check_case(12'b0000_0010_1111, 1'b0, 3'b010, 4'b1100, "Round Up (47)");

        // 4. Significand Overflow (F = 1111 + 1 -> F = 1000, E = E + 1)
        check_case(12'b0000_0111_1101, 1'b0, 3'b100, 4'b1000, "Sig Overflow (125 -> 128)");
        check_case(-12'd125,           1'b1, 3'b100, 4'b1000, "Neg Sig Overflow (-125 -> -128)");

        // 5. Exponent Saturation & Most Negative Input (-2048 and +2047)
        check_case(12'd2047,           1'b0, 3'b111, 4'b1111, "Max PositiveSaturation (2047)");
        check_case(12'b1000_0000_0000, 1'b1, 3'b111, 4'b1111, "Min Negative Edge Case (-2048)");

        // 6. Sweep all 4096 inputs to verify no X/Z states occur
        $display("=== Sweeping all 4096 possible 12-bit inputs ===");
        for (i = 0; i < 4096; i = i + 1) begin
            D = i[11:0];
            #2;
            if (^S === 1'bx || ^E === 1'bx || ^F === 1'bx) begin
                $display("[ERROR] Unknown state at D=%b", D);
                errors = errors + 1;
            end
        end

        $display("=== Verification Complete: %0d Errors ===", errors);
        $finish;
    end

endmodule