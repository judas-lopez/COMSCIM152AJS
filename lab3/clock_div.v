`timescale 1ns / 1ps

module clock_div(
    input wire clk,
    output reg clk_1hz = 0,
    output reg clk_2hz = 0,
    output reg clk_fast = 0,
    output reg clk_blink = 0
);

    reg [31:0] cnt_1hz = 0;
    reg [31:0] cnt_2hz = 0;
    reg [31:0] cnt_fast = 0;
    reg [31:0] cnt_blink = 0;

    // 1 Hz clock: 100,000,000 / (2 * 1) = 50,000,000
    always @(posedge clk) begin
        if (cnt_1hz == 49999999) begin
            cnt_1hz <= 0;
            clk_1hz <= ~clk_1hz;
        end else begin
            cnt_1hz <= cnt_1hz + 1;
        end
    end

    // 2 Hz clock: 100,000,000 / (2 * 2) = 25,000,000
    always @(posedge clk) begin
        if (cnt_2hz == 24999999) begin
            cnt_2hz <= 0;
            clk_2hz <= ~clk_2hz;
        end else begin
            cnt_2hz <= cnt_2hz + 1;
        end
    end

    // 400 Hz multiplexing & debounce clock: 100,000,000 / (2 * 400) = 125,000
    always @(posedge clk) begin
        if (cnt_fast == 124999) begin
            cnt_fast <= 0;
            clk_fast <= ~clk_fast;
        end else begin
            cnt_fast <= cnt_fast + 1;
        end
    end

    // 4 Hz blink clock: 100,000,000 / (2 * 4) = 12,500,000
    always @(posedge clk) begin
        if (cnt_blink == 12499999) begin
            cnt_blink <= 0;
            clk_blink <= ~clk_blink;
        end else begin
            cnt_blink <= cnt_blink + 1;
        end
    end

endmodule