`timescale 1ns/1ps
module tb_inputs(input wire clk, output reg done=0);
    reg reset=1, tick_ms=0, running=0, sample_valid=0;
    reg [9:0] x=512, y=512;
    wire tune_event, tune_up, coarse;
    joystick_tuning #(.REPEAT_MS(5)) stick(.*);

    // contacts indexed by physical column and row, both starting at the top left.
    reg [15:0] contacts=0;
    wire [3:0] col_active, row_n;
    wire key_event; wire [3:0] key;
    keypad pad(.*);
    genvar r;
    generate for (r=0;r<4;r=r+1) begin : rows
        assign row_n[r] = !((col_active[0] && contacts[r]) ||
                            (col_active[1] && contacts[4+r]) ||
                            (col_active[2] && contacts[8+r]) ||
                            (col_active[3] && contacts[12+r]));
    end endgenerate
    integer events=0;
    reg [3:0] last_key;
    always @(posedge clk) if (key_event) begin events<=events+1; last_key<=key; end
    task step; @(negedge clk); endtask
    task check(input logic condition, input string why);
        if (condition !== 1'b1) $fatal(1,"inputs: %s",why);
    endtask
    task scan_slots(input integer n);
        repeat(n) begin repeat(4) step(); tick_ms=1; step(); tick_ms=0; end
    endtask
    task sample(input integer h,input integer v); begin
        x=h; y=v; sample_valid=1; step(); sample_valid=0;
    end endtask
    // Key values across each physical row, from the silk screen.
    localparam [63:0] LABELS=64'h123A456B789C0FED;
    integer row,column,index;
    initial begin
        step(); reset=0; running=1;
        sample(520,480); check(!tune_event,"center");
        sample(900,512); check(tune_event && tune_up && !coarse,"right");
        sample(900,512); check(!tune_event,"hold suppressed before repeat");
        scan_slots(5); sample(900,512); check(tune_event && !coarse,"held repeat");
        sample(80,512); check(tune_event && !tune_up && !coarse,"left");
        sample(80,900); check(tune_event && tune_up && coarse,"up priority");
        sample(900,70); check(tune_event && !tune_up && coarse,"down priority");
        sample(512,512); scan_slots(10); sample(512,512); check(!tune_event,"release");
        running=0; sample(900,900); check(!tune_event,"paused stick");

        // A short closure must disappear before debounce emits an event.
        scan_slots(16); contacts=1; scan_slots(4); contacts=0; scan_slots(16);
        check(events==0,"bounce rejected");
        for (row=0;row<4;row=row+1) for (column=0;column<4;column=column+1) begin
            index=4*row+column;
            contacts=16'b1 << (4*column+row); scan_slots(32);
            check(events==index+1 && last_key==LABELS[60-4*index +:4],"key mapping and held press");
            contacts=0; scan_slots(16);
        end
        contacts=16'h0011; scan_slots(20); contacts=16'h0010; scan_slots(20);
        check(events==16,"chord blocked until release");
        contacts=0; scan_slots(16); contacts=16'h0010; scan_slots(16);
        check(events==17 && last_key==2,"release rearms");
        $display("PASS inputs: all 16 keypad positions, debounce, chords, joystick direction and repeat");
        done=1;
    end
endmodule
