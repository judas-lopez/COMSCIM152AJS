`timescale 1ns / 1ps

//==============================================================================
// Top-Level Module: FPCVT
// Must match signature FPCVT(D, S, E, F) for the grading script
//==============================================================================
module FPCVT(
    input  wire [11:0] D,
    output wire        S,
    output wire [2:0]  E,
    output wire [3:0]  F
);

    wire [11:0] mag;
    wire [2:0]  exp_unrounded;
    wire [3:0]  sig_unrounded;
    wire        fifth_bit;

    // Stage 1: Convert 12-bit Two's Complement to Sign-Magnitude
    twos_comp_to_mag u_stage1 (
        .D   (D),
        .S   (S),
        .mag (mag)
    );

    // Stage 2: Count Leading Zeroes and Extract Significand + 5th Bit
    priority_extract u_stage2 (
        .mag       (mag),
        .E_out     (exp_unrounded),
        .F_out     (sig_unrounded),
        .fifth_bit (fifth_bit)
    );

    // Stage 3: Round Significand and Handle Significand/Exponent Overflow
    fp_rounder u_stage3 (
        .E_in      (exp_unrounded),
        .F_in      (sig_unrounded),
        .fifth_bit (fifth_bit),
        .E_out     (E),
        .F_out     (F)
    );

endmodule

//==============================================================================
// Stage 1: Two's Complement to Sign-Magnitude Converter
//==============================================================================
module twos_comp_to_mag(
    input  wire [11:0] D,
    output wire        S,
    output reg  [11:0] mag
);

    assign S = D[11];

    always @(*) begin
        if (D == 12'b1000_0000_0000) begin
            // Edge Case: -2048 clamps to maximum positive magnitude 2047
            mag = 12'b0111_1111_1111;
        end else if (D[11] == 1'b1) begin
            // Negative numbers: invert and add 1
            mag = ~D + 12'd1;
        end else begin
            // Non-negative numbers pass through unchanged
            mag = D;
        end
    end

endmodule

//==============================================================================
// Stage 2: Leading Zero Priority Encoder & Bit Window Extractor
//==============================================================================
module priority_extract(
    input  wire [11:0] mag,
    output reg  [2:0]  E_out,
    output reg  [3:0]  F_out,
    output reg         fifth_bit
);

    always @(*) begin
        casex (mag)
            12'b01xx_xxxx_xxxx: begin // 1 leading zero
                E_out     = 3'd7;
                F_out     = mag[10:7];
                fifth_bit = mag[6];
            end
            12'b001x_xxxx_xxxx: begin // 2 leading zeroes
                E_out     = 3'd6;
                F_out     = mag[9:6];
                fifth_bit = mag[5];
            end
            12'b0001_xxxx_xxxx: begin // 3 leading zeroes
                E_out     = 3'd5;
                F_out     = mag[8:5];
                fifth_bit = mag[4];
            end
            12'b0000_1xxx_xxxx: begin // 4 leading zeroes
                E_out     = 3'd4;
                F_out     = mag[7:4];
                fifth_bit = mag[3];
            end
            12'b0000_01xx_xxxx: begin // 5 leading zeroes
                E_out     = 3'd3;
                F_out     = mag[6:3];
                fifth_bit = mag[2];
            end
            12'b0000_001x_xxxx: begin // 6 leading zeroes
                E_out     = 3'd2;
                F_out     = mag[5:2];
                fifth_bit = mag[1];
            end
            12'b0000_0001_xxxx: begin // 7 leading zeroes
                E_out     = 3'd1;
                F_out     = mag[4:1];
                fifth_bit = mag[0];
            end
            default: begin            // >= 8 leading zeroes
                E_out     = 3'd0;
                F_out     = mag[3:0];
                fifth_bit = 1'b0;
            end
        endcase
    end

endmodule

//==============================================================================
// Stage 3: Rounding & Overflow/Saturation Logic
//==============================================================================
module fp_rounder(
    input  wire [2:0] E_in,
    input  wire [3:0] F_in,
    input  wire       fifth_bit,
    output reg  [2:0] E_out,
    output reg  [3:0] F_out
);

    always @(*) begin
        if (fifth_bit == 1'b0) begin
            // Round down (truncate)
            E_out = E_in;
            F_out = F_in;
        end else begin
            // Round up (+1)
            if (F_in == 4'b1111) begin
                // Significand overflow (15 + 1 = 16)
                if (E_in == 3'b111) begin
                    // Exponent saturation at maximum FP value (E=7, F=15)
                    E_out = 3'b111;
                    F_out = 4'b1111;
                end else begin
                    // Right-shift significand to 8 and increment exponent
                    E_out = E_in + 3'd1;
                    F_out = 4'b1000;
                end
            end else begin
                // Normal round up without overflow
                E_out = E_in;
                F_out = F_in + 4'd1;
            end
        end
    end

endmodule