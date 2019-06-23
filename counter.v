`timescale 1us/1ns

module counter(input wire clk, reset,
               output reg [3:0] s);

  always @(posedge clk or posedge reset)
    begin
      if (reset)
        s <= 0;
      else
        s <= s + 4'd1;
    end
endmodule

module counter_tb();
  reg clk, reset;
  wire [3:0]s;

  counter dut(clk, reset, s);

  initial begin
    clk = 0;
    reset = 1;
    forever begin
      #5; clk = ~clk;
    end
  end

  initial begin
    $dumpfile("counter.vcd");
    $dumpvars(0, counter_tb);
    $monitor("s = %d", s);

    @(posedge clk);
    reset <= 0;

    repeat(5)
    begin
      @(posedge clk);
    end

    @(posedge clk);
    reset <= 1;

    @(posedge clk);
    reset <= 0;

    repeat(5)
    begin
      @(posedge clk);
    end

    $finish;
  end
endmodule