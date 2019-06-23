`timescale 1us/1ns

module instr_mem(input wire a,
                 output wire rd);
  reg [31:0] mem[63:0];

  initial
    $readmemb("code.bin", mem);

  assign rd = mem[a];
endmodule

module register(input wire clk, reset,
                input wire [7:0] d,
                output reg [7:0] q);
  always @(posedge clk or posedge reset)
    if (reset)
      q <= 0;
    else
      q <= d;
endmodule

module register_tb();
  reg  clk, reset;
  reg  [7:0] d;
  wire [7:0] q;

  register dut(clk, reset, d, q);

  initial begin
    clk = 0;
    reset = 1;
    d = 0;
    forever begin
      #5; clk = ~clk;
    end
  end

  initial begin
    $dumpfile("counter.vcd");
    $dumpvars(0, register_tb);
    $monitor("q = %b", q);

    @(posedge clk);
    reset <= 0;
    d <= 11010010;

    @(posedge clk);

    @(negedge clk);
    reset <= 1;

    $finish;
  end
endmodule

// module testbench();
//   reg clk, reset;
//   reg a, b, c, yexpected;
//   wire y;
//   reg[31:0] vectornum, errors;
//   reg[3:0]  testvectors[10000:0];

//   // instantiate device under test
//   sillyfunction dut(.a(a), .b(b), .c(c), .y(y) );

//   // generate clock
//   always     // no sensitivity list, so it always executes
//     begin
//       clk = 1; #5; clk = 0; #5; // 10ns period
//     end

//   initial
//     begin
//       $display("--------------------------");
//       $display("Loading testvectors");
//       $display("--------------------------");
//       $readmemb("example.tv", testvectors); // Read vectors
//       vectornum = 0; errors = 0;
//       reset = 1; #27; reset = 0;

//       $display("--------------------------");
//       $display("Running testbench");
//       $display("--------------------------");
//     end

//   always @(posedge clk)
//     begin
//       #1; {a, b, c, yexpected} = testvectors[vectornum];
//     end

//   always @(negedge clk)
//     if (!reset)
//     begin
//       if (y !== yexpected)
//       begin
//         $display("Error: input = %b", {a, b, c});
//         $display("       expected = %b", yexpected);
//         $display("       actual = %b", y);
//         errors = errors + 1;
//       end

//       vectornum = vectornum + 1;
//       if (testvectors[vectornum] === 4'bx)
//       begin
//         $display("--------------------------");
//         $display("%d tests completed", vectornum);
//         $display("%d error(s)", errors);
//         $display("--------------------------");
//         $finish;
//       end
//     end
// endmodule