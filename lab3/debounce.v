`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/05/2026 12:19:54 PM
// Design Name: 
// Module Name: debounce
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


module debounce(
    input wire clk,
    input wire clk_tick,
    input wire i,
    output reg o
);
    reg[7:0] shift;
    always @(posedge clk) begin
        if (clk_tick) begin
            shift <= {shift[6:0], i};
            if (&{shift[6:0], i}) o <= 1;
            else if (~|{shift[6:0], i}) o <= 0;
        end
    end
endmodule
