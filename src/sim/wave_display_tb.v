`timescale 1ns/1ps

module wave_display_tb;
  reg clk=0, reset=1;
  reg [10:0] x;
  reg [9:0]  y;
  reg valid;
  reg read_index;

  wire [8:0] read_address;
  wire valid_pixel;
  wire [7:0] r,g,b;

  wire [7:0] ram_dout;

  wave_display dut(
    .clk(clk), .reset(reset),
    .x(x), .y(y), .valid(valid),
    .read_value(ram_dout),
    .read_index(read_index),
    .read_address(read_address),
    .valid_pixel(valid_pixel),
    .r(r), .g(g), .b(b)
  );

  // fake RAM
  fake_sample_ram ram(
    .clk(clk),
    .addr(read_address[7:0]), // ignore MSB 
    .dout(ram_dout)
  );

  always #5 clk = ~clk;

  // helper
  task tick;
    @(posedge clk);
  endtask

  integer i;
  reg test1_fail, test2_fail, test3_fail;

  initial begin
    // defaults
    x=0; y=0; valid=0; read_index=0;
    test1_fail = 0;
    test2_fail = 0;
    test3_fail = 0;

    // reset
    repeat(5) tick();
    reset = 0;


    // test 1: Sweep in draw region, quadrant 001
    valid = 1;
    y = 10'd120;       // top half
    read_index = 0;

    repeat(3) tick(); // pipeline fill

    for (i=0; i<256; i=i+1) begin
      x = 11'b001_000000000 + i;
      tick();

      if (valid_pixel) begin
        if (r !== 8'hFF || g !== 8'hFF || b !== 8'hFF)
          test1_fail = 1;
      end
    end

    if (test1_fail)
      $display("TEST 1 FAIL: incorrect RGB when drawing");
    else
      $display("TEST 1 PASS: sweep in draw region");

    // test 2: valid = 0 must suppress drawing
    valid = 0;
    y = 10'd120;
    x = 11'b001_000001000;

    repeat(10) begin
      tick();
      if (valid_pixel !== 1'b0)
        test2_fail = 1;
    end

    if (test2_fail)
      $display("TEST 2 FAIL: drew when valid=0");
    else
      $display("TEST 2 PASS: valid gating");

    // test 3: bottom half must suppress drawing
    valid = 1;
    y = 10'b1_000000000;   // bottom half
    x = 11'b001_000001000;

    repeat(10) begin
      tick();
      if (valid_pixel !== 1'b0)
        test3_fail = 1;
    end

    if (test3_fail)
      $display("TEST 3 FAIL: drew in bottom half");
    else
      $display("TEST 3 PASS: top-half gating");


    // summary
    if (!test1_fail && !test2_fail && !test3_fail)
      $display("ALL TESTS PASSED.");
    else
      $display("ONE OR MORE TESTS FAILED.");

    $finish;
  end

endmodule