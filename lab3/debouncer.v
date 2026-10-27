`timescale 1ns / 1ps

module debouncer(
    input wire clk_fast,
    input wire in_sig,
    output reg out_sig = 0
);

    reg [2:0] shift_reg = 3'b000;

    always @(posedge clk_fast) begin
        shift_reg <= {shift_reg[1:0], in_sig};
        if (shift_reg == 3'b111)
            out_sig <= 1'b1;
        else if (shift_reg == 3'b000)
            out_sig <= 1'b0;
    end

endmodule