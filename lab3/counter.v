`timescale 1ns / 1ps

module counter(
    input wire clk_1hz,
    input wire clk_2hz,
    input wire clk_fast,
    input wire rst,
    input wire pause,
    input wire sel,
    input wire adj,
    output reg [3:0] min1 = 0,
    output reg [3:0] min0 = 0,
    output reg [3:0] sec1 = 0,
    output reg [3:0] sec0 = 0
);

    // Toggle pause state on rising edge of debounced pause button
    reg paused = 0;
    reg pause_prev = 0;

    always @(posedge clk_fast) begin
        pause_prev <= pause;
        if (pause && !pause_prev) begin
            paused <= ~paused;
        end
    end

    // Select 2Hz clock in adjust mode, 1Hz clock in normal mode
    wire clk_cnt = adj ? clk_2hz : clk_1hz;

    // Main stopwatch counter
    always @(posedge clk_cnt or posedge rst) begin
        if (rst) begin
            min1 <= 4'd0;
            min0 <= 4'd0;
            sec1 <= 4'd0;
            sec0 <= 4'd0;
        end else if (!paused) begin
            if (!adj) begin
                // Normal mode: increment seconds and roll over to minutes
                if (sec0 == 4'd9) begin
                    sec0 <= 4'd0;
                    if (sec1 == 4'd5) begin
                        sec1 <= 4'd0;
                        if (min0 == 4'd9) begin
                            min0 <= 4'd0;
                            if (min1 == 4'd5)
                                min1 <= 4'd0;
                            else
                                min1 <= min1 + 1'b1;
                        end else begin
                            min0 <= min0 + 1'b1;
                        end
                    end else begin
                        sec1 <= sec1 + 1'b1;
                    end
                end else begin
                    sec0 <= sec0 + 1'b1;
                end
            end else begin
                // Adjust mode (2Hz): sel = 0 adjusts minutes, sel = 1 adjusts seconds
                if (sel == 1'b0) begin
                    if (min0 == 4'd9) begin
                        min0 <= 4'd0;
                        if (min1 == 4'd5)
                            min1 <= 4'd0;
                        else
                            min1 <= min1 + 1'b1;
                    end else begin
                        min0 <= min0 + 1'b1;
                    end
                end else begin
                    if (sec0 == 4'd9) begin
                        sec0 <= 4'd0;
                        if (sec1 == 4'd5)
                            sec1 <= 4'd0;
                        else
                            sec1 <= sec1 + 1'b1;
                    end else begin
                        sec0 <= sec0 + 1'b1;
                    end
                end
            end
        end
    end

endmodule