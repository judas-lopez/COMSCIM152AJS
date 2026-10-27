`timescale 1ns / 1ps

module stopwatch(
    input wire clk,          // 100MHz master clock (W5)
    input wire rst,          // Reset button (btnR - T17)
    input wire pause,        // Pause button (btnC - U18)
    input wire sel,          // Select switch (sw[0] - V17)
    input wire adj,          // Adjust switch (sw[1] - V16)
    output wire [6:0] seg,   // 7-seg cathodes (CA to CG)
    output wire [3:0] an     // 7-seg anodes (AN3 to AN0)
);

    // Divided clock signals
    wire clk_1hz;
    wire clk_2hz;
    wire clk_fast;
    wire clk_blink;

    // Debounced inputs
    wire rst_db;
    wire pause_db;
    wire sel_db;
    wire adj_db;

    // 4-bit BCD digits for MM:SS
    wire [3:0] min1;
    wire [3:0] min0;
    wire [3:0] sec1;
    wire [3:0] sec0;

    // 1. Clock Divider
    clock_div u_clk_div (
        .clk(clk),
        .clk_1hz(clk_1hz),
        .clk_2hz(clk_2hz),
        .clk_fast(clk_fast),
        .clk_blink(clk_blink)
    );

    // 2. Debouncers for buttons and switches
    debouncer db_rst (
        .clk_fast(clk_fast),
        .in_sig(rst),
        .out_sig(rst_db)
    );

    debouncer db_pause (
        .clk_fast(clk_fast),
        .in_sig(pause),
        .out_sig(pause_db)
    );

    debouncer db_sel (
        .clk_fast(clk_fast),
        .in_sig(sel),
        .out_sig(sel_db)
    );

    debouncer db_adj (
        .clk_fast(clk_fast),
        .in_sig(adj),
        .out_sig(adj_db)
    );

    // 3. Stopwatch Counter Logic
    counter u_counter (
        .clk_1hz(clk_1hz),
        .clk_2hz(clk_2hz),
        .clk_fast(clk_fast),
        .rst(rst_db),
        .pause(pause_db),
        .sel(sel_db),
        .adj(adj_db),
        .min1(min1),
        .min0(min0),
        .sec1(sec1),
        .sec0(sec0)
    );

    // 4. 7-Segment Display Controller
    display u_display (
        .clk_fast(clk_fast),
        .clk_blink(clk_blink),
        .adj(adj_db),
        .sel(sel_db),
        .min1(min1),
        .min0(min0),
        .sec1(sec1),
        .sec0(sec0),
        .seg(seg),
        .an(an)
    );

endmodule