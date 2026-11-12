`timescale 1ns/1ps
// Original six-pin PmodJSTK. SPI mode 0, MSB first, five bytes under one chip select.
module jstk_reader #(
    parameter integer CLK_HZ = 100000000,
    parameter integer SPI_HZ = 250000
) (
    input wire clk, reset, miso,
    output reg cs_n, sck,
    output wire mosi,
    output reg [9:0] x, y,
    output reg sample_valid
);
    localparam integer HALF = CLK_HZ / (2 * SPI_HZ);
    localparam integer GAP = (CLK_HZ + 49999) / 50000; // >=20 us
    localparam integer POLL = CLK_HZ / 100;             // 10 ms between polls
    localparam WAIT_POLL=0, WAIT_BYTE=1, LOW_HALF=2, HIGH_HALF=3;
    reg [1:0] state;
    reg [$clog2(POLL+1)-1:0] delay_count;
    reg [2:0] bit_index, byte_index;
    reg [7:0] rx_byte, x_low, y_low;
    reg [9:0] x_pending, y_pending;
    (* ASYNC_REG = "TRUE" *) reg [1:0] miso_sync;
    // Send 0x80 (LED update with both lights off) followed by four zero bytes.
    assign mosi = !cs_n && byte_index == 0 && bit_index == 7;

    always @(posedge clk) begin
        miso_sync <= {miso_sync[0], miso};
        sample_valid <= 0;
        if (reset) begin
            state <= WAIT_POLL;
            delay_count <= 0;
            cs_n <= 1;
            sck <= 0;
            byte_index <= 0;
            bit_index <= 7;
            rx_byte <= 0;
            x <= 512;
            y <= 512;
            x_low <= 0;
            y_low <= 0;
            x_pending <= 512;
            y_pending <= 512;
        end else if (delay_count != 0) begin
            delay_count <= delay_count - 1'b1;
        end else begin
            case (state)
                WAIT_POLL: begin
                    cs_n <= 0;
                    byte_index <= 0;
                    bit_index <= 7;
                    delay_count <= GAP-1;
                    state <= WAIT_BYTE;
                end
                WAIT_BYTE: begin
                    delay_count <= HALF-1;
                    state <= LOW_HALF;
                end
                LOW_HALF: begin
                    sck <= 1;
                    rx_byte <= {rx_byte[6:0], miso_sync[1]};
                    delay_count <= HALF-1;
                    state <= HIGH_HALF;
                end
                HIGH_HALF: begin
                    sck <= 0;
                    if (bit_index != 0) begin
                        bit_index <= bit_index-1'b1;
                        delay_count <= HALF-1;
                        state <= LOW_HALF;
                    end else begin
                        case (byte_index)
                            0: x_low <= rx_byte;
                            1: x_pending <= {rx_byte[1:0], x_low};
                            2: y_low <= rx_byte;
                            3: y_pending <= {rx_byte[1:0], y_low};
                            default: begin x <= x_pending; y <= y_pending; end
                        endcase
                        bit_index <= 7;
                        if (byte_index == 4) begin
                            cs_n <= 1;
                            sample_valid <= 1;
                            delay_count <= POLL-1;
                            state <= WAIT_POLL;
                        end else begin
                            byte_index <= byte_index+1'b1;
                            delay_count <= GAP-1;
                            state <= WAIT_BYTE;
                        end
                    end
                end
            endcase
        end
    end
endmodule

module joystick_tuning #(
    parameter SWAP_XY=0, INVERT_X=0, INVERT_Y=0,
    parameter integer REPEAT_MS=110
) (
    input wire clk, reset, tick_ms, running, sample_valid,
    input wire [9:0] x, y,
    output reg tune_event, tune_up, coarse
);
    wire [9:0] raw_h = SWAP_XY ? y : x;
    wire [9:0] raw_v = SWAP_XY ? x : y;
    wire [9:0] h = INVERT_X ? 10'd1023-raw_h : raw_h;
    wire [9:0] v = INVERT_Y ? 10'd1023-raw_v : raw_v;
    localparam NEUTRAL=0, LEFT=1, RIGHT=2, DOWN=3, UP=4;
    wire [2:0] direction = v > 700 ? UP : v < 324 ? DOWN :
                           h > 700 ? RIGHT : h < 324 ? LEFT : NEUTRAL;
    reg [2:0] last_direction;
    reg [$clog2(REPEAT_MS+1)-1:0] cooldown;
    always @(posedge clk) begin
        tune_event <= 0;
        if (reset || !running) begin
            last_direction <= NEUTRAL;
            cooldown <= 0;
            coarse <= 0;
            tune_up <= 0;
        end else begin
            if (tick_ms && cooldown != 0) cooldown <= cooldown-1'b1;
            if (sample_valid) begin
                last_direction <= direction;
                if (direction == NEUTRAL) cooldown <= 0;
                else if (direction != last_direction || cooldown == 0) begin
                    tune_event <= 1;
                    tune_up <= direction == UP || direction == RIGHT;
                    coarse <= direction == UP || direction == DOWN;
                    cooldown <= REPEAT_MS;
                end
            end
        end
    end
endmodule
