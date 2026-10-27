`timescale 1ns / 1ps

module display(
    input wire clk_fast,
    input wire clk_blink,
    input wire adj,
    input wire sel,
    input wire [3:0] min1,
    input wire [3:0] min0,
    input wire [3:0] sec1,
    input wire [3:0] sec0,
    output reg [6:0] seg,
    output reg [3:0] an
);

    reg [1:0] digit_idx = 2'b00;
    reg [3:0] cur_digit;
    reg blink_off;

    // Cycle through the 4 anodes at 400Hz
    always @(posedge clk_fast) begin
        digit_idx <= digit_idx + 1'b1;
    end

    // Select active anode and current digit
    always @(*) begin
        blink_off = 1'b0;
        case (digit_idx)
            2'b00: begin
                an = 4'b1110; // AN0: sec0 (rightmost)
                cur_digit = sec0;
                if (adj && sel && clk_blink)
                    blink_off = 1'b1;
            end
            2'b01: begin
                an = 4'b1101; // AN1: sec1
                cur_digit = sec1;
                if (adj && sel && clk_blink)
                    blink_off = 1'b1;
            end
            2'b10: begin
                an = 4'b1011; // AN2: min0
                cur_digit = min0;
                if (adj && !sel && clk_blink)
                    blink_off = 1'b1;
            end
            2'b11: begin
                an = 4'b0111; // AN3: min1 (leftmost)
                cur_digit = min1;
                if (adj && !sel && clk_blink)
                    blink_off = 1'b1;
            end
            default: begin
                an = 4'b1111;
                cur_digit = 4'd0;
            end
        endcase
    end

    // Active-low 7-seg decoder: seg[6:0] = {CG, CF, CE, CD, CC, CB, CA}
    always @(*) begin
        if (blink_off) begin
            seg = 7'b1111111; // Blank digit for blinking
        end else begin
            case (cur_digit)
                4'd0: seg = 7'b1000000;
                4'd1: seg = 7'b1111001;
                4'd2: seg = 7'b0100100;
                4'd3: seg = 7'b0110000;
                4'd4: seg = 7'b0011001;
                4'd5: seg = 7'b0010010;
                4'd6: seg = 7'b0000010;
                4'd7: seg = 7'b1111000;
                4'd8: seg = 7'b0000000;
                4'd9: seg = 7'b0010000;
                default: seg = 7'b1111111;
            endcase
        end
    end

endmodule