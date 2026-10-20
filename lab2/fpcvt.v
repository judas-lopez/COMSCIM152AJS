module fpcvt (
  input wire [11:0] D,
  output reg S,
  output reg [2:0] E,
  output reg [3:0] F
);

    reg [11:0] abs_D;
    reg [11:0] shifted_D;
    integer i;
    reg foundOne;
    reg [3:0] F_unrounded;
    wire [3:0] LZ;
    
    priority_encoder u_enc (
      .D(abs_D),
      .LZ(LZ)
    );
    
    always @(*) begin
        // twos complement
        S = 0;
        abs_D = D;
        if (D[11] == 1) begin
            S = 1;
            abs_D = ~D + 1;
        end
    
        if (LZ == 0) begin
            E = 3'b111;
            F = 4'b1111;
        end
        else if (LZ > 8) begin
            E = 0;
            F = abs_D[3:0];
        end
        else begin
            E = 8 - LZ;
            shifted_D = abs_D << LZ;
            if (shifted_D[7] == 1) begin
                if (shifted_D[11:8] == 4'b1111) begin
                    if (E == 7) begin
                        F = 4'b1111;
                    end
                    else begin
                        E = E + 1;
                        F = 4'b1000;
                    end
                end
                else begin
                  F = shifted_D[11:8] + 1;
                end
            end
            else begin
              F = shifted_D[11:8];
            end
        end
    end
endmodule

module priority_encoder (
  input wire [11:0] D,
  output reg [3:0] LZ
);

    always @(*) begin
        casez (D)
          12'b1???????????: LZ = 0;
          12'b?1??????????: LZ = 1;
          12'b??1?????????: LZ = 2;
          12'b???1????????: LZ = 3;
          12'b????1???????: LZ = 4;
          12'b?????1??????: LZ = 5;
          12'b??????1?????: LZ = 6;
          12'b???????1????: LZ = 7;
          12'b????????1???: LZ = 8;
          12'b?????????1??: LZ = 9;
          12'b??????????1?: LZ = 10;
          12'b???????????1: LZ = 11;
          default: LZ = 12;
        endcase
    end

endmodule