module mcu(
    input clk,
    input reset,
    input play_button,
    input next_button,
    output reg play,
    output reg reset_player,
    output reg [1:0] song,
    input song_done
);

    // Implementation goes here!
    parameter PAUSED = 1'b0; 
    parameter PLAYING = 1'b1; 
    
    reg state, next_state; 
    reg [1:0] next_song; 
    
    //make sure to start in a PAUSED state, song 0
    always @(posedge clk) begin 
        if (reset) begin 
            state <= PAUSED;
            song <= 2'd0;
        end else begin
            state <= next_state;
            song <= next_song; 
        end
    end 
    
    //next_button -> progress (wraps), reset, PAUSE
    //song_done -> keep same song, reset, PAUSE
    //next_state -> play toggles
    always @(*) begin 
        next_state = state;
        next_song = song; 
        reset_player = 1'b0;
        play = (state == PLAYING);
        
        if(play_button) begin
            next_state = (state == PLAYING) ? PAUSED : PLAYING;
        end else if(next_button) begin 
            next_song = song + 2'd1;
            next_state = PAUSED; 
            reset_player = 1'b1; 
        end else if(song_done && state == PLAYING) begin
            next_state = PAUSED;
            reset_player = 1'b1;
        end 
    end 
   
endmodule