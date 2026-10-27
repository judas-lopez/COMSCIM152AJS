`timescale 1ns / 1ps

module counter_tb;

    // Inputs
    reg clk_1hz;
    reg clk_2hz;
    reg clk_fast;
    reg rst;
    reg pause;
    reg sel;
    reg adj;

    // Outputs
    wire [3:0] min1;
    wire [3:0] min0;
    wire [3:0] sec1;
    wire [3:0] sec0;

    // Instantiate the Counter Unit Under Test (UUT)
    counter uut (
        .clk_1hz(clk_1hz),
        .clk_2hz(clk_2hz),
        .clk_fast(clk_fast),
        .rst(rst),
        .pause(pause),
        .sel(sel),
        .adj(adj),
        .min1(min1),
        .min0(min0),
        .sec1(sec1),
        .sec0(sec0)
    );

    // Generate scaled clocks for simulation:
    // clk_fast = 100MHz (10ns period)
    // clk_2hz  = 25MHz  (40ns period)
    // clk_1hz  = 12.5MHz (80ns period)
    always #5  clk_fast = ~clk_fast;
    always #20 clk_2hz  = ~clk_2hz;
    always #40 clk_1hz  = ~clk_1hz;

    initial begin
        // Initialize inputs
        clk_1hz = 0;
        clk_2hz = 0;
        clk_fast = 0;
        rst = 0;
        pause = 0;
        sel = 0;
        adj = 0;

        // 1. Apply initial reset to 00:00
        #20;
        rst = 1;
        #40;
        rst = 0;

        // 2. Normal counting mode (adj = 0, sel = 0)
        // Let it count past 65 seconds to verify 00:59 -> 01:00 rollover
        #5300;

        // 3. Test Pause button (press once to pause)
        pause = 1;
        #30;
        pause = 0;
        // Wait while paused (counter values should stay frozen)
        #500;

        // Press Pause again to resume counting
        pause = 1;
        #30;
        pause = 0;
        #400;

        // 4. Test Adjust Minutes mode (adj = 1, sel = 0)
        // Seconds should freeze, minutes should increment at 2Hz
        adj = 1;
        sel = 0;
        #1000;

        // 5. Test Adjust Seconds mode (adj = 1, sel = 1)
        // Minutes should freeze, seconds should increment at 2Hz
        sel = 1;
        #1000;

        // 6. Return to normal counting and let it wrap around 59:59 -> 00:00
        adj = 0;
        sel = 0;
        // Adjust minutes up to 59 quickly to test the 59:59 rollover
        adj = 1;
        sel = 0;
        wait (min1 == 4'd5 && min0 == 4'd9);
        
        // Adjust seconds close to 59
        sel = 1;
        wait (sec1 == 4'd5 && sec0 == 4'd7);

        // Switch back to normal mode to watch 59:58 -> 59:59 -> 00:00
        adj = 0;
        #500;

        // 7. Test asynchronous Reset mid-count
        rst = 1;
        #50;
        rst = 0;
        #200;

        $finish;
    end

endmodule