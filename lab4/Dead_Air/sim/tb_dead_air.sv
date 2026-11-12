`timescale 1ns/1ps
module tb_dead_air;
    reg clk=0;
    always #5 clk=~clk;
    wire game_done,audio_done,input_done,panel_done,board_done;
    tb_game      game_suite  (clk && !game_done,game_done);
    tb_audio     audio_suite (clk && !audio_done,audio_done);
    tb_inputs    input_suite (clk && !input_done,input_done);
    tb_panel_amp panel_suite (clk && !panel_done,panel_done);
    tb_board     board_suite (clk && !board_done,board_done);
    initial begin
        wait(game_done && audio_done && input_done && panel_done && board_done);
        $display("PASS Dead Air: all five suites");
        $finish;
    end
    initial begin #150000000; $fatal(1,"Test timeout"); end
endmodule
