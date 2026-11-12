`timescale 1ns/1ps
module dead_air_top #(
    parameter integer CLK_HZ=100000000,
    parameter SWAP_XY=0, INVERT_X=0, INVERT_Y=0
) (
    input wire clk, btnC, btnU,
    input wire [2:0] sw,
    output wire [15:0] led,
    output wire [6:0] seg,
    output wire [3:0] an,
    output wire dp,
    input wire joy_miso,
    output wire joy_cs_n, joy_mosi, joy_sck,
    input wire [3:0] key_row_n,
    output wire [3:0] key_col_n,
    output wire amp_ain, amp_gain, amp_shutdown_n
);
    // FPGA configuration initializes this shift register at power-up.
    reg [7:0] startup = 8'hFF;
    always @(posedge clk) startup <= {startup[6:0],1'b0};
    wire power_reset=startup[7];
    localparam integer MS_DIV=CLK_HZ/1000;
    reg [$clog2(MS_DIV+1)-1:0] divider;
    wire tick_ms=divider==MS_DIV-1;
    always @(posedge clk)
        if (power_reset || tick_ms) divider<=0;
        else divider<=divider+1'b1;

    (* ASYNC_REG = "TRUE" *) reg [2:0] sw_meta, sw_sync;
    always @(posedge clk) begin sw_meta<=sw; sw_sync<=sw_meta; end
    wire center_press, reset_level;
    button_filter upper_button(.clk(clk),.reset(power_reset),.tick_ms(tick_ms),
        .raw(btnU),.level(reset_level),.press());
    wire reset=power_reset || reset_level;
    button_filter center_button(.clk(clk),.reset(reset),.tick_ms(tick_ms),
        .raw(btnC),.level(),.press(center_press));

    wire [9:0] x, y, frequency;
    wire sample_valid, tune_event, tune_up, coarse, key_event;
    wire [3:0] key;
    wire [1:0] completed, entry_len;
    wire [11:0] entry, message;
    wire [7:0] strength, seconds;
    wire locked, running, paused, won, lost, error, tone;
    jstk_reader #(.CLK_HZ(CLK_HZ)) joystick(
        .clk(clk),.reset(reset),.miso(joy_miso),.cs_n(joy_cs_n),.sck(joy_sck),
        .mosi(joy_mosi),.x(x),.y(y),.sample_valid(sample_valid)
    );
    joystick_tuning #(.SWAP_XY(SWAP_XY),.INVERT_X(INVERT_X),.INVERT_Y(INVERT_Y)) tuning(
        .clk(clk),.reset(reset),.tick_ms(tick_ms),.running(running),
        .sample_valid(sample_valid),.x(x),.y(y),.tune_event(tune_event),.tune_up(tune_up),.coarse(coarse)
    );
    wire [3:0] col_active;
    keypad keys(.clk(clk),.reset(reset),.tick_ms(tick_ms),.row_n(key_row_n),
        .col_active(col_active),.key_event(key_event),.key(key));
    // Only the selected column drives low. The other three FPGA pins float.
    genvar col;
    generate for (col=0; col<4; col=col+1) begin: column_pins
        assign key_col_n[col] = col_active[col] ? 1'b0 : 1'bz;
    end endgenerate
    game controller(
        .clk(clk),.reset(reset),.tick_ms(tick_ms),.center_press(center_press),
        .hard_select(sw_sync[2]),.tune_event(tune_event),.tune_up(tune_up),.coarse(coarse),
        .key_event(key_event),.key(key),.frequency(frequency),.seconds(seconds),.entry(entry),
        .entry_len(entry_len),.completed(completed),.message(message),.locked(locked),
        .running(running),.paused(paused),.won(won),.lost(lost),.error(error),.strength(strength)
    );
    morse_sender #(.UNIT_CYCLES((CLK_HZ/1000)*150)) transmitter(
        .clk(clk),.reset(reset),.enable(locked),.message(message),.tone(tone)
    );
    amp2_driver #(.CLK_HZ(CLK_HZ)) speaker(.clk(clk),.reset(reset),.tone(tone),
        .ain(amp_ain),.gain(amp_gain),.shutdown_n(amp_shutdown_n));
    display panel(.clk(clk),.reset(reset),.tick_ms(tick_ms),.mode(sw_sync[1:0]),
        .completed(completed),.entry_len(entry_len),.frequency(frequency),.seconds(seconds),
        .entry(entry),.seg(seg),.an(an),.dp(dp));

    assign led = {won,lost,error,paused,completed>=3,completed>=2,completed>=1,locked,strength};
endmodule

module button_filter (
    input wire clk, reset, tick_ms, raw,
    output reg level, press
);
    (* ASYNC_REG = "TRUE" *) reg [1:0] sync;
    reg [3:0] different_ms;
    always @(posedge clk) begin
        sync <= {sync[0],raw};
        press <= 0;
        if (reset) begin level<=0; different_ms<=0; end
        else if (tick_ms) begin
            if (sync[1]==level) different_ms<=0;
            else if (different_ms==9) begin
                level<=sync[1];
                press<=sync[1];
                different_ms<=0;
            end else different_ms<=different_ms+1'b1;
        end
    end
endmodule
