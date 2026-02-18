`timescale 1ns/1ps

module wave_capture_tb ();
  reg clk;
  reg reset;
  reg new_sample_ready;
  reg [15:0] new_sample_in;
  reg wave_display_idle;

  wire [8:0] write_address;
  wire write_enable;
  wire [7:0] write_sample;
  wire read_index;

  wave_capture dut (
    .clk(clk),
    .reset(reset),
    .new_sample_ready(new_sample_ready),
    .new_sample_in(new_sample_in),
    .wave_display_idle(wave_display_idle),
    .write_address(write_address),
    .write_enable(write_enable),
    .write_sample(write_sample),
    .read_index(read_index)
  );

  initial clk = 1'b0;
  always #5 clk = ~clk;

  task send_sample(input [15:0] s);
    begin
      @(negedge clk);
      new_sample_in = s;
      new_sample_ready = 1'b1;
      @(negedge clk);
      new_sample_ready = 1'b0;
    end
  endtask

  integer i;
  integer write_count;
  reg start_read_index;
  reg expected_bank;
  reg [7:0] expected_counter;

  always @(posedge clk) begin
    if (write_enable) begin
      if (write_address[8] !== expected_bank) begin
        $display("ERROR @%0t: bank bit mismatch got=%b exp=%b", $time, write_address[8], expected_bank);
        $finish;
      end
      if (write_address[7:0] !== expected_counter) begin
        $display("ERROR @%0t: counter mismatch got=%0d exp=%0d", $time, write_address[7:0], expected_counter);
        $finish;
      end

      if (write_sample !== (new_sample_in[15:8] + 8'd128)) begin
        $display("ERROR @%0t: write_sample mismatch got=%0d exp=%0d",
                 $time, write_sample, (new_sample_in[15:8] + 8'd128));
        $finish;
      end

      write_count = write_count + 1;
      expected_counter = expected_counter + 8'd1;
    end
  end

 initial begin
      reset = 1'b1;
      new_sample_ready = 1'b0;
      new_sample_in = 16'd0;
      wave_display_idle = 1'b0;
    
      write_count = 0;
      expected_counter = 8'd0;
    
      repeat (3) @(posedge clk);
      reset = 1'b0;
      @(posedge clk);
    
      start_read_index = read_index;
      expected_bank = ~start_read_index;
    
      send_sample(16'h8000); 
      send_sample(16'h0001); 
    
      i = 0;
      while (write_count < 256 && i < 800) begin
        send_sample(16'h0100 + i[15:0]);
        i = i + 1;
      end
    
      if (write_count !== 256) begin
        $display("ERROR: expected 256 writes, got %0d (iterations=%0d)", write_count, i);
        $finish;
      end
    
      repeat (5) begin
        @(posedge clk);
        if (write_enable) begin
          $display("ERROR @%0t: write_enable still high after 256 writes", $time);
          $finish;
        end
      end
    
      @(negedge clk);
      wave_display_idle = 1'b1;
      @(negedge clk);
      wave_display_idle = 1'b0;
    
      repeat (2) @(posedge clk);
      if (read_index === start_read_index) begin
        $display("ERROR: read_index did not toggle after wave_display_idle");
        $finish;
      end
    
      $display("PASS: wave_capture captured 256 samples and toggled read_index.");
      $finish;
    end

endmodule
