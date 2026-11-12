`timescale 1ns/1ps
// Game rules and the three station records. All inputs are synchronous, single-clock events.
module game (
    input wire clk, reset, tick_ms, center_press, hard_select,
    input wire tune_event, tune_up, coarse, key_event,
    input wire [3:0] key,
    output reg [9:0] frequency,
    output reg [7:0] seconds,
    output reg [11:0] entry,
    output reg [1:0] entry_len, completed,
    output reg [11:0] message,
    output wire locked, running, paused, won, lost, error,
    output wire [7:0] strength
);
    localparam IDLE=3'd0, PLAY=3'd1, PAUSE=3'd2, WIN=3'd3, LOSS=3'd4;
    reg [2:0] state;
    reg hard;
    reg [9:0] target, ms_in_second, error_ms;
    assign running = state == PLAY;
    assign paused = state == PAUSE;
    assign won = state == WIN;
    assign lost = state == LOSS;
    assign error = error_ms != 0;

    // Frequency is binary. Message and keypad entry are packed decimal digits.
    always @* begin
        case (completed)
            2'd0: begin target = 10'd137; message = 12'h482; end
            2'd1: begin target = 10'd482; message = 12'h756; end
            default: begin target = 10'd756; message = 12'h029; end
        endcase
    end
    wire [9:0] distance = (frequency >= target) ? frequency-target : target-frequency;
    assign locked = running && (distance <= (hard ? 10'd0 : 10'd2));
    // Each bit has a successively narrower threshold. Full scale means lock.
    assign strength = running ? {locked, distance<=5, distance<=12, distance<=25,
                                 distance<=50, distance<=100, distance<=200, distance<=500} : 8'd0;
    wire [9:0] step_size = coarse ? 10'd10 : 10'd1;
    wire second_due = tick_ms && ms_in_second == 10'd999;
    wire submit = key_event && key == 4'hA && entry_len == 3 && locked;
    wire wrong = submit && entry != message;
    wire [7:0] after_tick = second_due ? seconds-8'd1 : seconds;

    always @(posedge clk) begin
        if (reset) begin
            state <= IDLE;
            frequency <= 0;
            seconds <= 0;
            ms_in_second <= 0;
            entry <= 0;
            entry_len <= 0;
            completed <= 0;
            hard <= 0;
            error_ms <= 0;
        end else begin
            // A wrong submission lights the indicator for one wall-clock second.
            if (tick_ms && error_ms != 0) error_ms <= error_ms - 1'b1;
            case (state)
                IDLE: if (center_press) begin
                    state <= PLAY;
                    hard <= hard_select;
                    seconds <= hard_select ? 8'd120 : 8'd180;
                end
                PAUSE: if (center_press) state <= PLAY;
                PLAY: begin
                    if (tick_ms) begin
                        ms_in_second <= second_due ? 10'd0 : ms_in_second + 1'b1;
                        if (second_due) seconds <= after_tick;
                    end
                    // Expiration wins even if the final correct submit arrives on this clock.
                    if (second_due && seconds == 1) begin
                        state <= LOSS;
                    end else if (center_press) begin
                        state <= PAUSE;
                    end else begin
                        if (tune_event) begin
                            if (tune_up)
                                frequency <= frequency > 10'd999-step_size ? 10'd999 : frequency+step_size;
                            else
                                frequency <= frequency < step_size ? 10'd0 : frequency-step_size;
                        end
                        // Submissions use the lock and frequency shown before this clock edge.
                        if (wrong) begin
                            error_ms <= 10'd1000;
                            if (after_tick <= 8'd10) begin
                                seconds <= 0;
                                state <= LOSS;
                            end else seconds <= after_tick-8'd10;
                        end else if (submit) begin
                            completed <= completed + 1'b1;
                            entry <= 0;
                            entry_len <= 0;
                            if (completed == 2) state <= WIN;
                        end else if (key_event) begin
                            if (key <= 9 && entry_len < 3) begin
                                entry <= {entry[7:0], key};
                                entry_len <= entry_len + 1'b1;
                            end else if (key == 4'hB && entry_len != 0) begin
                                entry <= {4'b0, entry[11:4]};
                                entry_len <= entry_len - 1'b1;
                            end else if (key == 4'hC) begin
                                entry <= 0;
                                entry_len <= 0;
                            end
                        end
                    end
                end
                default: ; // Won and Lost hold until reset.
            endcase
        end
    end
endmodule
