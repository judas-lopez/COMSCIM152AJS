`timescale 1ns / 1ps

module tb;

    reg [11:0] D;
    wire S;
    wire [2:0] E;
    wire [3:0] F;
    
    initial begin
        run_test(12'b000000101100, 1'b0, 3'b010, 4'b1011);
        run_test(12'b000000101101, 1'b0, 3'b010, 4'b1011);
        run_test(12'b000000101110, 1'b0, 3'b010, 4'b1100);
        run_test(12'b000000101111, 1'b0, 3'b010, 4'b1100);
        run_test(12'b000000000110, 1'b0, 3'b000, 4'b0110);
        run_test(12'b111001011010, 1'b1, 3'b101, 4'b1101);
        run_test(12'b000110110110, 1'b0, 3'b101, 4'b1110);
        run_test(12'b000001111101, 1'b0, 3'b100, 4'b1000);
        run_test(12'b011111111111, 1'b0, 3'b111, 4'b1111);
    
        $display("PASS");
    end
    
    task run_test(input [11:0] data, input expected_S, input [2:0] expected_E, input [3:0] expected_F);
      begin
          D = data;
          #100;
          $display("%d\t %b\t %b\t %b\t %b\t", $time, D, S, E, F);
          if (S !== expected_S || E !== expected_E || F !== expected_F) begin
            $display("FAIL");
            $finish;
          end
      end
    endtask
    
    fpcvt uut_(
      // outputs
      .S (S),
      .E (E),
      .F (F),
      
      // inputs
      .D (D)
    );

endmodule
