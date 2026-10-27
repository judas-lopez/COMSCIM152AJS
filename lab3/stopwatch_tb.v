`timescale 1ns / 1ps

module stopwatch_tb;

    // Inputs
    reg clk;
    reg rst;
    reg pause;
    reg sel;
    reg adj;

    // Outputs
    wire [6:0] seg;
    wire [3:0] an;

    // Instantiate Top-Level Stopwatch
    stopwatch uut (
        .clk(clk),
        .rst(rst),
        .pause(pause),
        .sel(sel),
        .adj(adj),
        .seg(seg),
        .an(an)
    );

    // 100MHz master clock (10ns period)
    always #5 clk = ~clk;

    initial begin
        // Initialize inputs
        clk = 0;
        rst = 0;
        pause = 0;
        sel = 0;
        adj = 0;

        // 1. Hold reset long enough to pass the 3-bit debouncer shift register
        #20;
        rst = 1;
        #200;
        rst = 0;

        // 2. Run in Normal Mode and observe anode cycling (an) and cathodes (seg)
        #3000;

        // 3. Simulate a noisy/bouncy pause button press
        pause = 1; #10;
        pause = 0; #10; // bounce glitch (filtered out by debouncer)
        pause = 1; #200; // stable press (latched by debouncer)
        pause = 0;
        #1000;

        // Unpause
        pause = 1; #200;
        pause = 0;
        #1000;

        // 4. Test Adjust Minutes with Blinking (adj = 1, sel = 0)
        // Observe seg occasionally becoming 7'b1111111 when AN3/AN2 are active
        adj = 1;
        sel = 0;
        #2000;

        // 5. Test Adjust Seconds with Blinking (adj = 1, sel = 1)
        sel = 1;
        #2000;

        // Return to Normal Mode
        adj = 0;
        sel = 0;
        #1000;

        $finish;
    end

endmodule