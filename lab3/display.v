`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/27/2026 01:37:21 PM
// Design Name: 
// Module Name: display
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module display(
    input wire clk_refresh,
    input wire clk_blinking,
    input wire adj,
    input wire sel,
    input wire[3:0] min0,
    input wire[3:0] min1,
    input wire[3:0] sec1,
    input wire[3:0] sec0,
    output reg[6:0] seg,
    output reg[3:0] an
);

    reg [1:0] digit = 0;
    reg [3:0] value = 0;
    reg is_blinking = 0;
    
    always @(posedge clk_refresh) begin
        digit <= digit + 1'b1;
    end
    
    always @(posedge clk_blinking) begin
        is_blinking <= !is_blinking;
    end
    
    always @(*) begin
        an = 4'b1111;
        value = 0;

        case (digit)
            0: begin value = sec0; an = 4'b1110; end
            1: begin value = sec1; an = 4'b1101; end
            2: begin value = min0; an = 4'b1011; end
            3: begin value = min1; an = 4'b0111; end
        endcase
        
        if (adj && is_blinking) begin
            seg = 7'b1111111;
        end else begin
            case (value)
                0: seg = 7'b1000000;
                1: seg = 7'b1111001;
                2: seg = 7'b0100100;
                3: seg = 7'b0110000;
                4: seg = 7'b0011001;
                5: seg = 7'b0010010;
                6: seg = 7'b0000010;
                7: seg = 7'b1111000;
                8: seg = 7'b0000000;
                9: seg = 7'b0010000;
                default: seg = 7'b1111111;
            endcase
        end
    end

endmodule
