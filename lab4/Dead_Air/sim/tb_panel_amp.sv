`timescale 1ns/1ps
module tb_panel_amp(input wire clk, output reg done=0);
    reg reset=1, tick_ms=0, tone=0;
    reg [1:0] mode=0, completed=0, entry_len=0;
    reg [9:0] frequency=0;
    reg [7:0] seconds=7;
    reg [11:0] entry=12'h029;
    wire [6:0] seg; wire [3:0] an; wire dp;
    display panel(.*);
    wire ain,gain,shutdown_n;
    amp2_driver #(.CLK_HZ(716800),.TONE_HZ(700)) amp(.*); // 512 clocks per half-note
    task step; @(negedge clk); endtask
    function [6:0] seven(input integer d);
        case(d)
            0:seven=64; 1:seven=121; 2:seven=36; 3:seven=48; 4:seven=25;
            5:seven=18; 6:seven=2; 7:seven=120; 8:seven=0; default:seven=16;
        endcase
    endfunction
    task scan(input integer value,input integer shown);
        integer pos,divisor;
        begin
            divisor=1;
            for (pos=0;pos<4;pos=pos+1) begin
                #1;
                if (pos<shown) begin
                    if (an !== (~(4'b0001<<pos)) || seg !== seven((value/divisor)%10))
                        $fatal(1,"display: value=%d digit=%d",value,pos);
                end else if (an!==4'hF) $fatal(1,"display blanking");
                if (dp!==1) $fatal(1,"decimal point");
                tick_ms=1; step(); tick_ms=0; divisor=divisor*10;
            end
        end
    endtask
    integer i, high_ticks;
    task pwm_frame(output integer high_count);
        integer n;
        begin
            high_count=0;
            // Sample at negedge, beginning at carrier==0.
            for(n=0;n<256;n=n+1) begin
                if (ain===1) high_count=high_count+1;
                else if (ain!==0) $fatal(1,"unknown AMP2 output");
                step();
            end
        end
    endtask
    reg saw_low,saw_high;
    initial begin
        step(); if (shutdown_n!==0 || gain!==1) $fatal(1,"amp reset pins");
        reset=0;
        for(i=0;i<1000;i=i+1) begin frequency=i; scan(i,3); end
        mode=1; scan(7,3);
        mode=2; entry_len=3; scan(29,3); entry_len=2; entry=2; scan(2,2);
        entry_len=0; scan(0,0);
        mode=3; for(i=0;i<4;i=i+1) begin completed=i; scan(i==3 ? 3 : i+1,1); end
        reset=1; step(); reset=0; #1;
        if (shutdown_n!==1) $fatal(1,"amp enabled");
        pwm_frame(high_ticks); if (high_ticks!=128) $fatal(1,"idle PWM");
        tone=1; pwm_frame(high_ticks);
        saw_low=0; saw_high=0;
        repeat(6) begin
            pwm_frame(high_ticks);
            if (high_ticks==120) saw_low=1;
            else if (high_ticks==136) saw_high=1;
            else $fatal(1,"unexpected PWM duty");
        end
        if (!saw_low||!saw_high) $fatal(1,"PWM note must have both half cycles");
        tone=0; pwm_frame(high_ticks); pwm_frame(high_ticks);
        if (high_ticks!=128) $fatal(1,"PWM returns to silence");
        $display("PASS panel and AMP2: 000..999, four display modes, blanking, and audio PWM");
        done=1;
    end
endmodule
