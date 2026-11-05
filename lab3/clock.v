`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/27/2026 01:18:22 PM
// Design Name: 
// Module Name: clock
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


module clock_divider(
  input wire clk,
  output wire clk_1hz,
  output wire clk_2hz,
  output wire clk_cycling,
  output wire clk_blinking
);
  clock #(.DIV(100000000)) clk_1 (.clk(clk), .clk_out(clk_1hz));
  clock #(.DIV(50000000)) clk_2 (.clk(clk), .clk_out(clk_2hz));
  clock #(.DIV(100000)) clk_c (.clk(clk), .clk_out(clk_cycling));
  clock #(.DIV(25000000)) clk_b (.clk(clk), .clk_out(clk_blinking));
endmodule

module clock#(
  parameter DIV = 10
)(
  input wire clk,
  output reg clk_out
);

  localparam HALF = DIV / 2;
  localparam WIDTH = $clog2(HALF);
  reg [WIDTH-1:0] counter;

  always @(posedge clk) begin
    if (counter == HALF - 1) begin
        counter <= 0;
        clk_out <= ~clk_out;
    end
    else begin
        counter <= counter + 1;
    end
  end
endmodule
