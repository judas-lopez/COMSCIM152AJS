`timescale 1ns/1ps
module display (
    input wire clk, reset, tick_ms,
    input wire [1:0] mode, completed, entry_len,
    input wire [9:0] frequency,
    input wire [7:0] seconds,
    input wire [11:0] entry,
    output reg [6:0] seg,
    output reg [3:0] an,
    output wire dp
);
    // Three BCD digits suffice for all values shown (0..999).
    function [11:0] to_bcd;
        input [9:0] value;
        reg [11:0] acc;
        integer bit_i;
        begin
            acc=0;
            for (bit_i=9; bit_i>=0; bit_i=bit_i-1) begin
                if (acc[3:0]>=5) acc[3:0]=acc[3:0]+3;
                if (acc[7:4]>=5) acc[7:4]=acc[7:4]+3;
                if (acc[11:8]>=5) acc[11:8]=acc[11:8]+3;
                acc={acc[10:0],value[bit_i]};
            end
            to_bcd=acc;
        end
    endfunction
    wire [11:0] number = to_bcd(mode==1 ? {2'b0,seconds} : frequency);
    reg [11:0] digits;
    reg [1:0] visible, scan;
    reg [3:0] digit;
    always @(posedge clk)
        if (reset) scan<=0;
        else if (tick_ms) scan<=scan+1'b1;
    always @* begin
        case (mode)
            2: begin digits=entry; visible=entry_len; end
            3: begin digits=completed>=2 ? 12'h003 : {10'd0, completed+2'd1}; visible=1; end
            default: begin digits=number; visible=3; end
        endcase
        case (scan)
            0: digit=digits[3:0];
            1: digit=digits[7:4];
            default: digit=digits[11:8];
        endcase
        an = scan < visible ? ~(4'b0001 << scan) : 4'b1111;
        // Active low; bit 0=a, bit 6=g.
        case (digit)
            0: seg=7'h40; 1: seg=7'h79; 2: seg=7'h24; 3: seg=7'h30; 4: seg=7'h19;
            5: seg=7'h12; 6: seg=7'h02; 7: seg=7'h78; 8: seg=7'h00; 9: seg=7'h10;
            default: seg=7'h7F;
        endcase
    end
    assign dp=1'b1;
endmodule
