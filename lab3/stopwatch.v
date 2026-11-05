`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/27/2026 12:28:41 PM
// Design Name: 
// Module Name: stopwatch
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

module stopwatch(
  input wire clk,
  input wire rst,
  input wire en,
  input wire adj,
  input wire sel,
  output wire[3:0] min1,
  output wire[3:0] min0,
  output wire[3:0] sec1,
  output wire[3:0] sec0
);
    
   wire carry_sec0;
   wire carry_sec1;
   wire carry_min0;
   
    mod_n_counter #(.MOD(10)) dut_sec0 (
        .clk(clk), .rst(rst), .en(en && (!adj || sel === 1)), .count(sec0), .c_out(carry_sec0)
    );
    
    mod_n_counter #(.MOD(6)) dut_sec1 (
        .clk(clk), .rst(rst), .en(en && (!adj || sel === 1) && carry_sec0), .count(sec1), .c_out(carry_sec1)
    );
    
    mod_n_counter #(.MOD(10)) dut_min0 (
        .clk(clk), .rst(rst), .en(en && ((!adj && carry_sec1) || (adj && !sel))), .count(min0), .c_out(carry_min0)
    );
    
    mod_n_counter #(.MOD(10)) dut_min1 (
        .clk(clk), .rst(rst), .en(en && ((!adj && carry_sec1) || (adj && !sel)) && carry_min0), .count(min1)
    );
endmodule

module mod_n_counter #(
  parameter MOD = 10,
  parameter WIDTH = 4
)(
  input wire clk,
  input wire rst,
  input wire en,
  output reg [WIDTH-1:0] count,
  output wire c_out
);
    assign c_out = en && (count == MOD - 1);
    always @(posedge clk) begin
       if (rst) begin
         count <= 0;
       end
       else if (en) begin
         if (count === MOD - 1) begin
            count <= 0;
         end
         else begin
            count <= count + 1;
         end
       end
    end
endmodule
