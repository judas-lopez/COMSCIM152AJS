`timescale 1ns/1ps
module tb_audio(input wire clk, output reg done=0);
    localparam U=4;
    reg reset=1, enable=0;
    reg [11:0] message=0;
    wire tone;
    morse_sender #(.UNIT_CYCLES(U)) dut(.*);
    task step; @(negedge clk); endtask
    // Independent rule for numeric Morse: 1..5 start with n dots, 6..9 start with n-5 dashes.
    function integer mark_length(input integer digit, input integer i);
        if (digit==0 || (digit<=5 && i>=digit) || (digit>5 && i<digit-5)) mark_length=3;
        else mark_length=1;
    endfunction
    task duration(input bit expected, input integer units);
        integer n;
        for(n=0;n<units*U;n=n+1) begin
            if (tone !== expected) $fatal(1,"Morse duration: msg=%h expected=%b offset=%0d",message,expected,n);
            step();
        end
    endtask
    task listen_message(input logic [11:0] digits);
        integer d,i,value;
        for(d=0;d<3;d=d+1) begin
            value=(digits >> ((2-d)*4)) & 15;
            for(i=0;i<5;i=i+1) begin
                duration(1,mark_length(value,i));
                duration(0,i<4 ? 1 : (d<2 ? 3 : 7));
            end
        end
    endtask
    task listen_twice(input logic [11:0] digits); begin
        enable=0; step(); message=digits; enable=1; step();
        listen_message(digits); listen_message(digits);
    end endtask
    initial begin
        step(); reset=0;
        listen_twice(12'h012); listen_twice(12'h345); listen_twice(12'h678);
        listen_twice(12'h902); listen_twice(12'h482); listen_twice(12'h756); listen_twice(12'h029);
        repeat(3*U+2) step(); enable=0; #1;
        if (tone !== 0) $fatal(1,"disable must silence immediately");
        repeat(11) step(); enable=1; step(); listen_message(12'h029);
        $display("PASS Morse: all ten digits, exact mark/gap lengths, repeat and restart");
        done=1;
    end
endmodule
