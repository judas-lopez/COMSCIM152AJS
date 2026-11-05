`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/27/2026 01:43:29 PM
// Design Name: 
// Module Name: top
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


module top(
    input wire clk,
    input wire rst,
    input wire pause,
    output wire[6:0] seg,
    output wire[3:0] an,
    input wire adj,
    input wire sel
); 
    wire[3:0] sec0, sec1, min0, min1;

    wire clk_1hz, clk_2hz, clk_cycling, clk_blinking;
    
    clock_divider clk_div (
        .clk(clk),
        .clk_1hz(clk_1hz), .clk_2hz(clk_2hz), .clk_cycling(clk_cycling), .clk_blinking(clk_blinking)
    );
    
    wire clean_rst;
    
    debounce debounce_rst(
        .clk(clk), .clk_tick(clk_cycling), .i(rst), .o(clean_rst)
    );

    stopwatch watch (
        .clk(adj ? clk_2hz : clk_1hz), .rst(clean_rst), .en(!pause), .adj(adj), .sel(sel),
        .sec0(sec0), .sec1(sec1), .min0(min0), .min1(min1)
    );
    
    display dsp (
        .clk_refresh(clk_cycling), .clk_blinking(clk_blinking), .adj(adj), .sel(sel),
        .min0(min0), .min1(min1), .sec0(sec0), .sec1(sec1),
        .seg(seg), .an(an)
    );
    
endmodule
