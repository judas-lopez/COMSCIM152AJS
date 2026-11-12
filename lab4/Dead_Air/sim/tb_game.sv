`timescale 1ns/1ps
module tb_game(input wire clk, output reg done=0);
    reg reset=1, tick_ms=0, center_press=0, hard_select=0;
    reg tune_event=0, tune_up=0, coarse=0, key_event=0;
    reg [3:0] key=0;
    wire [9:0] frequency;
    wire [7:0] seconds, strength;
    wire [11:0] message, entry;
    wire [1:0] completed, entry_len;
    wire locked, running, paused, won, lost, error;
    game dut(.*);
    task step; begin @(negedge clk); end endtask
    task check(input logic condition, input string why);
        if (condition !== 1'b1) $fatal(1,"game: %s",why);
    endtask
    task center; begin center_press=1; step(); center_press=0; end endtask
    task restart(input bit hard); begin
        reset=1; step(); reset=0; hard_select=hard; center();
    end endtask
    task push(input logic [3:0] k); begin
        key=k; key_event=1; step(); key_event=0;
    end endtask
    task move_stick(input bit increase, input bit ten, input integer count); begin
        tune_up=increase; coarse=ten; tune_event=1; repeat(count) step(); tune_event=0;
    end endtask
    task tune_to(input integer target); integer diff; begin
        diff=target-frequency;
        if (diff>=0) begin move_stick(1,1,diff/10); move_stick(1,0,diff%10); end
        else begin diff=-diff; move_stick(0,1,diff/10); move_stick(0,0,diff%10); end
    end endtask
    task enter_digits(input logic [11:0] digits); begin
        push(digits[11:8]); push(digits[7:4]); push(digits[3:0]);
    end endtask
    task elapse(input integer ms); begin
        tick_ms=1; repeat(ms) step(); tick_ms=0;
    end endtask
    reg [7:0] far_bar;
    initial begin
        step();
        check(!running && !won && !lost && completed==0 && entry_len==0,"reset to Idle");
        restart(0);
        check(running && seconds==180,"easy start");
        hard_select=1;
        move_stick(0,1,2); check(frequency==0,"lower saturation");
        move_stick(1,1,100); check(frequency==999,"upper saturation");
        tune_to(482); check(!locked,"future station must be inactive");
        enter_digits(12'h482); push(10);
        check(seconds==180 && completed==0 && entry_len==3,"unlocked submit");
        push(12); push(0); push(2); push(4'hD); push(4'hE); push(4'hF);
        check(entry_len==2 && entry==12'h002,"zero and unused keys");
        push(9); push(7); check(entry_len==3 && entry==12'h029,"fourth digit ignored");
        push(11); check(entry_len==2 && entry==12'h002,"backspace");
        push(12); push(11); check(entry_len==0 && entry==0,"clear and empty backspace");
        tune_to(300); far_bar=strength; tune_to(134);
        check(!locked && strength>far_bar,"strength increases, three outside easy lock");
        tune_to(135); check(locked && strength==255,"easy lower bound and difficulty latch");
        tune_to(139); check(locked,"easy upper bound"); tune_to(140); check(!locked,"past upper bound");
        tune_to(137); push(4); push(10); check(seconds==180 && entry_len==1,"incomplete");
        push(12); enter_digits(12'h111); elapse(999);
        tick_ms=1; push(10); tick_ms=0;
        check(seconds==169 && error && completed==0,"simultaneous tick and penalty");
        elapse(999); check(error,"error lasts a second"); elapse(1); check(!error && seconds==168,"error clears");
        push(12); enter_digits(12'h482); elapse(400); center();
        check(paused && !locked,"pause"); elapse(2200); move_stick(1,1,5); push(11); push(10);
        check(seconds==168 && frequency==137 && entry==12'h482 && !error,"pause freezes gameplay");
        center(); elapse(599); check(seconds==168,"fractional second retained");
        elapse(1); check(seconds==167 && locked,"resume");
        push(10); check(completed==1 && !locked && entry_len==0 && message==12'h756,"first answer");
        tune_to(482); enter_digits(12'h756); push(10); check(completed==2 && !locked,"second answer");
        tune_to(756); enter_digits(12'h029); push(10);
        check(won && !locked && completed==3 && entry_len==0,"win with leading zero");
        center(); move_stick(0,1,5); push(3); elapse(2000);
        check(won && seconds==167 && frequency==756 && entry_len==0,"win stays frozen");

        restart(1); hard_select=0;
        check(running && seconds==120 && frequency==0,"hard restart");
        tune_to(136); check(!locked,"hard one below"); tune_to(138); check(!locked,"hard one above");
        tune_to(137); check(locked,"hard exact");
        enter_digits(12'h999); repeat(11) push(10); elapse(3000);
        check(seconds==7 && !lost,"setup for small remainder");
        push(10); check(lost && seconds==0 && error && !locked,"penalty saturates");
        center(); move_stick(0,1,1); elapse(1100);
        check(lost && seconds==0 && frequency==137,"lost stays frozen");

        restart(1); tune_to(137); enter_digits(12'h111); repeat(11) push(10);
        push(12); enter_digits(12'h482); push(10);
        tune_to(482); enter_digits(12'h756); push(10);
        tune_to(756); enter_digits(12'h029); elapse(9999);
        check(seconds==1 && completed==2,"final second at final station");
        tick_ms=1; push(10); tick_ms=0;
        check(lost && !won && completed==2 && seconds==0,"expiration beats winning answer");
        reset=1; step();
        check(!lost && !won && !paused && !running && !error && frequency==0 &&
              completed==0 && entry_len==0,"reset clears finished round");
        $display("PASS game: three stations, both difficulties, timer priority, controls and penalties");
        done=1;
    end
endmodule
