`timescale 1ns/1ps
// Play a whole round via the top-level pins. The clock parameter uses 2 MHz
// to reduce simulation cycles. The SPI, millisecond and Morse ratios remain valid.
module tb_board(input wire clk, output reg done=0);
    localparam HZ=2000000;
    reg btnC=0, btnU=0;
    reg [2:0] sw=0;
    wire [15:0] led; wire [6:0] seg; wire [3:0] an; wire dp;
    wire joy_cs_n,joy_sck,joy_mosi;
    reg joy_miso=0;
    wire [3:0] key_row_n,key_col_n;
    wire amp_ain,amp_gain,amp_shutdown_n;
    dead_air_top #(.CLK_HZ(HZ)) dut(.*);

    reg [9:0] stick_x=512,stick_y=512;
    reg [39:0] packet, sent_by_host;
    integer spi_bits=0;
    time selected_at, previous_rise;
    always @(negedge joy_cs_n) begin
        packet={stick_x[7:0],6'b0,stick_x[9:8],stick_y[7:0],6'b0,stick_y[9:8],8'h05};
        spi_bits=0; sent_by_host=0; selected_at=$time;
        joy_miso=packet[39];
    end
    always @(posedge joy_sck) if (!joy_cs_n) begin
        if (spi_bits==0 && $time-selected_at<300) $fatal(1,"SPI chip-select setup below 15 us");
        if (spi_bits!=0 && spi_bits%8==0 && $time-previous_rise<200) $fatal(1,"SPI inter-byte gap");
        if (spi_bits%8!=0 && $time-previous_rise!=80) $fatal(1,"SPI clock rate");
        previous_rise=$time;
        sent_by_host={sent_by_host[38:0],joy_mosi};
        spi_bits=spi_bits+1;
    end
    always @(negedge joy_sck) if (!joy_cs_n && spi_bits<40) joy_miso=packet[39-spi_bits];
    always @(posedge dut.sample_valid) begin
        if (spi_bits!=40 || sent_by_host!==40'h8000000000) $fatal(1,"SPI frame or MOSI");
        if ({dut.x,dut.y} !== {packet[25:24],packet[39:32],packet[9:8],packet[23:16]})
            $fatal(1,"SPI axis byte order");
    end

    reg [15:0] contacts=0; // Physical keypad positions in row-major order.
    genvar r;
    generate for(r=0;r<4;r=r+1) begin: matrix_rows
        assign key_row_n[r] = !((key_col_n[0]===1'b0 && contacts[r*4]) ||
                                (key_col_n[1]===1'b0 && contacts[r*4+1]) ||
                                (key_col_n[2]===1'b0 && contacts[r*4+2]) ||
                                (key_col_n[3]===1'b0 && contacts[r*4+3]));
    end endgenerate
    task cycles(input integer n); repeat(n) @(negedge clk); endtask
    task ms(input integer n); cycles(n*(HZ/1000)); endtask
    task check(input logic condition,input string why);
        if (condition !== 1'b1) $fatal(1,"board: %s",why);
    endtask
    task sample(input integer h,input integer v); begin
        stick_x=h; stick_y=v;
        @(negedge joy_cs_n); @(posedge dut.sample_valid); cycles(3);
    end endtask
    task tune_to(input integer target);
        integer difference, previous;
        begin
            // Switch axes or briefly center for discrete steps, just like a player.
            while(dut.frequency!=target) begin
                difference=target-dut.frequency;
                previous=dut.frequency;
                if (difference>=10 && (stick_y==512 || difference==10)) sample(512,900);
                else sample(900,512);
                if (dut.frequency==previous) sample(512,512);
            end
            sample(512,512);
        end
    endtask
    localparam [63:0] LABELS=64'h123A456B789C0FED;
    task press_key(input logic [3:0] value);
        integer pos; begin
            for(pos=0;pos<16;pos=pos+1)
                if (LABELS[60-pos*4 +: 4]==value) contacts=16'h1<<pos;
            ms(20); contacts=0; ms(20);
        end
    endtask
    task submit(input logic [11:0] answer); begin
        press_key(answer[11:8]); press_key(answer[7:4]); press_key(answer[3:0]);
        check(dut.entry_len==3 && dut.entry==answer,"keypad entry");
        press_key(4'hA);
    end endtask
    task center; begin btnC=1; ms(14); btnC=0; ms(14); end endtask
    initial begin
        cycles(16); check(led==0,"Idle outputs");
        // A bouncing center contact shorter than the debounce interval cannot start a game.
        btnC=1; ms(3); btnC=0; ms(12); check(!dut.running,"button debounce");
        center(); check(dut.running && dut.seconds==180,"start via board button");
        tune_to(137); check(led[8:0]==9'h1FF && dut.tone,"first station lock and tone");
        center(); check(led[12] && !dut.tone && !led[8],"pause silences");
        center(); check(led[8] && dut.tone,"resume restarts first mark");
        sample(512,900); check(!led[8] && !dut.tone,"tune out silences");
        sample(512,50); sample(512,512); check(led[8] && dut.tone,"relock restarts first mark");
        submit(12'h482); check(led[11:9]==1 && !led[8],"station 1 complete");
        tune_to(482); submit(12'h756); check(led[11:9]==3,"station 2 complete");
        tune_to(756); sw=3'b010; submit(12'h029);
        check(led[15] && !led[14] && led[11:9]==7 && !led[8] && !dut.tone,"all stations won");
        btnU=1; ms(14); btnU=0; ms(14); check(led==0 && dut.frequency==0,"upper reset returns to Idle");
        $display("PASS board: full winning round through SPI, physical keypad matrix and board buttons");
        done=1;
    end
endmodule
