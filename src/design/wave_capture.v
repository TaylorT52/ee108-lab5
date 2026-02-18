module wave_capture (
    input clk,
    input reset,
    input new_sample_ready,
    input [15:0] new_sample_in,
    input wave_display_idle,

    output wire [8:0] write_address,
    output wire write_enable,
    output wire [7:0] write_sample,
    output reg read_index
);

//track states
parameter ARMED = 2'd0;
parameter ACTIVE = 2'd1; 
parameter WAIT = 2'd2; 
parameter DONE = 8'd255; 

reg next_read_index;
reg[1:0] state, next_state; 
reg[15:0] prev_sample;

wire zero_cross = (new_sample_in[15] == 1'b0) && (prev_sample[15] == 1'b1);
reg [7:0] counter; 

//writing to RAM
assign write_enable = (state == ACTIVE) && new_sample_ready;
assign write_sample = new_sample_in[15:8] + 8'd128;
assign write_address = {~read_index, counter};

//init at ARMED state
always @(posedge clk) begin 
    if (reset) begin
        state <= ARMED;
        prev_sample <= 16'd0;
        counter <= 1'b0;
        read_index <= 8'd0;
        
    end else begin
        state <= next_state;
        read_index <= next_read_index;
        
        //track a previous sample
        if (new_sample_ready) begin
            prev_sample <= new_sample_in;
        end 
        
        //zero and increment the counter for armed
        if (next_state == ARMED) begin
            counter <= 8'd0;
        end
        if (state == ACTIVE && new_sample_ready && counter != DONE) begin
           counter <= counter + 8'd1; 
        end
    end 
end 

always @(*) begin 
    next_state = state;
    next_read_index = read_index;
//armed
    if(state == ARMED) begin
        if(new_sample_ready && zero_cross) begin
            next_state = ACTIVE;
        end
    end
//active
    if(state == ACTIVE) begin
        if(counter == DONE && new_sample_ready) begin
            next_state = WAIT;
        end
    end
//waits
    if(state == WAIT) begin
        if(wave_display_idle == 1'b1) begin
            next_state = ARMED;
            next_read_index = ~read_index;
        end
    end
end 

endmodule
