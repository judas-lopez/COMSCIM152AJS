`timescale 1ns/1ps
// Logical index 0 is the top row / left column. XDC maps these onto KYPD J1.
module keypad #(
    parameter integer STABLE_FRAMES=3
) (
    input wire clk, reset, tick_ms,
    input wire [3:0] row_n,
    output wire [3:0] col_active,
    output reg key_event,
    output reg [3:0] key
);
    (* ASYNC_REG = "TRUE" *) reg [3:0] row_meta, row_sync;
    reg [1:0] column;
    assign col_active = reset ? 4'b0000 : 4'b0001 << column;

    reg [11:0] first_three;
    wire [15:0] frame = {~row_sync, first_three}; // used on the fourth column only
    wire multiple_keys = (frame & (frame-16'd1)) != 0;
    reg [15:0] candidate;
    reg [$clog2(STABLE_FRAMES+1)-1:0] stable_count;
    reg armed;
    function [3:0] lookup;
        input [15:0] one_hot;
        begin
            case (one_hot)
                16'h0001: lookup=1; 16'h0002: lookup=4; 16'h0004: lookup=7; 16'h0008: lookup=0;
                16'h0010: lookup=2; 16'h0020: lookup=5; 16'h0040: lookup=8; 16'h0080: lookup=4'hF;
                16'h0100: lookup=3; 16'h0200: lookup=6; 16'h0400: lookup=9; 16'h0800: lookup=4'hE;
                16'h1000: lookup=4'hA; 16'h2000: lookup=4'hB; 16'h4000: lookup=4'hC;
                default: lookup=4'hD;
            endcase
        end
    endfunction

    always @(posedge clk) begin
        row_meta <= row_n;
        row_sync <= row_meta;
        key_event <= 0;
        if (reset) begin
            column <= 0;
            first_three <= 0;
            candidate <= 0;
            stable_count <= 0;
            armed <= 0;
            key <= 0;
        end else if (tick_ms) begin
            column <= column+1'b1;
            case (column)
                0: first_three[3:0] <= ~row_sync;
                1: first_three[7:4] <= ~row_sync;
                2: first_three[11:8] <= ~row_sync;
                3: begin
                    if (multiple_keys) armed <= 0;
                    if (frame != candidate) begin
                        candidate <= frame;
                        stable_count <= 1;
                    end else begin
                        if (stable_count < STABLE_FRAMES) stable_count <= stable_count+1'b1;
                        if (stable_count >= STABLE_FRAMES-1) begin
                            if (frame == 0) armed <= 1;
                            else if (armed && !multiple_keys) begin
                                key_event <= 1;
                                key <= lookup(frame);
                                armed <= 0;
                            end
                        end
                    end
                end
            endcase
        end
    end
endmodule
