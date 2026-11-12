`timescale 1ns/1ps
module morse_sender #(
    parameter integer UNIT_CYCLES=15000000
) (
    input wire clk, reset, enable,
    input wire [11:0] message,
    output wire tone
);
    localparam IDLE=0, MARK=1, GAP=2;
    reg [1:0] state, digit_index;
    reg [2:0] symbol_index, units_left;
    reg [$clog2(UNIT_CYCLES+1)-1:0] cycles_left;
    wire [3:0] digit = digit_index == 0 ? message[11:8] :
                       digit_index == 1 ? message[7:4] : message[3:0];
    function [4:0] pattern;
        input [3:0] n;
        begin
            case (n)  // First symbol at bit 4. 0 is dot, 1 is dash.
                0: pattern=5'b11111; 1: pattern=5'b01111;
                2: pattern=5'b00111; 3: pattern=5'b00011;
                4: pattern=5'b00001; 5: pattern=5'b00000;
                6: pattern=5'b10000; 7: pattern=5'b11000;
                8: pattern=5'b11100; 9: pattern=5'b11110;
                default: pattern=0;
            endcase
        end
    endfunction
    wire [4:0] symbols = pattern(digit);
    wire [2:0] mark_units = symbols[4-symbol_index] ? 3'd3 : 3'd1;
    assign tone = enable && state == MARK;
    always @(posedge clk) begin
        if (reset || !enable) begin
            state <= IDLE;
            digit_index <= 0;
            symbol_index <= 0;
            units_left <= 0;
            cycles_left <= 0;
        end else if (state == IDLE) begin
            state <= MARK;
            units_left <= mark_units;
            cycles_left <= UNIT_CYCLES-1;
        end else if (cycles_left != 0) begin
            cycles_left <= cycles_left-1'b1;
        end else begin
            cycles_left <= UNIT_CYCLES-1;
            if (units_left > 1) units_left <= units_left-1'b1;
            else if (state == GAP) begin
                state <= MARK;
                units_left <= mark_units;
            end else begin
                state <= GAP;
                if (symbol_index != 4) begin
                    symbol_index <= symbol_index+1'b1;
                    units_left <= 1;
                end else begin
                    symbol_index <= 0;
                    if (digit_index == 2) begin
                        digit_index <= 0;
                        units_left <= 7;
                    end else begin
                        digit_index <= digit_index+1'b1;
                        units_left <= 3;
                    end
                end
            end
        end
    end
endmodule

// PWM DAC into the amplifier's AIN. Update duty at carrier boundaries.
module amp2_driver #(
    parameter integer CLK_HZ=100000000, TONE_HZ=700,
    parameter [7:0] AMPLITUDE=8'd8
) (
    input wire clk, reset, tone,
    output wire ain, gain, shutdown_n
);
    localparam integer HALF_PERIOD=CLK_HZ/(2*TONE_HZ);
    reg [$clog2(HALF_PERIOD+1)-1:0] count;
    reg polarity;
    reg [7:0] carrier, duty;
    always @(posedge clk) begin
        if (reset) begin
            count <= 0;
            polarity <= 0;
            carrier <= 0;
            duty <= 128;
        end else begin
            carrier <= carrier+1'b1;
            if (carrier == 255)
                duty <= !tone ? 8'd128 : polarity ? 8'd128+AMPLITUDE : 8'd128-AMPLITUDE;
            if (!tone) begin count <= 0; polarity <= 0; end
            else if (count == HALF_PERIOD-1) begin count <= 0; polarity <= !polarity; end
            else count <= count+1'b1;
        end
    end
    assign ain = carrier < duty;
    assign gain = 1'b1;          // PmodAMP2 lower gain setting, 6 dB
    assign shutdown_n = !reset;
endmodule
