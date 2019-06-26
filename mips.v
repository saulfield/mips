`timescale 1us/1ns

module lw_testbench();
  reg  clk, reg_wenable, mem_wenable;
  reg [2:0] alucontrol;
  reg [31:0] pc;

  top dut(clk, reg_wenable, mem_wenable, alucontrol, pc);

  initial begin
    clk = 0;
    pc = 0;
    reg_wenable = 1;
    mem_wenable = 0;
    alucontrol = 000;

    forever begin
      #5; clk = ~clk;
    end
  end

  initial begin
    $dumpfile("lw_testbench.vcd");
    $dumpvars(0, lw_testbench);
    // $monitor("rd = %b", rd);

    @(posedge clk);
    @(posedge clk);
    begin
      if(dut.regfile.registers[10] === 1) begin
        $display("Simulation succeeded");
      end 
      else begin
        $display("Simulation failed");
      end
    end
    $finish;
  end
endmodule

module top(input wire clk, reg_wenable, mem_wenable,
           input wire [2:0] alucontrol,
           input wire [31:0] pc);
  wire [4:0] temp_addr;
  wire [31:0] instr;
  wire [31:0] reg_rdata1, reg_rdata2;
  wire [31:0] signimm;
  wire [31:0] aluresult;
  wire zeroflag;
  wire [31:0] mem_rdata, mem_wdata;
  
  imem    imem(pc, instr);
  regfile regfile(clk, reg_wenable,
                  instr[20:16], mem_rdata,
                  instr[25:21], temp_addr,
                  reg_rdata1, reg_rdata2);
  signex  signex(instr[15:0], signimm);
  alu     alu(alucontrol,
              reg_rdata1, signimm,
              aluresult, zeroflag);
  dmem    dmem(clk, mem_wenable,
               aluresult, mem_wdata, 
               mem_rdata);
endmodule

module imem(input  wire [31:0] addr,
            output wire [31:0] rdata);
  reg [31:0] mem[63:0];

  initial
    $readmemb("code.dat", mem);

  assign rdata = mem[addr];
endmodule

module regfile(input  wire clk,   wenable,
               input  wire [4:0]  waddr,
               input  wire [31:0] wdata,
               input  wire [4:0]  raddr1, raddr2,
               output wire [31:0] rdata1, rdata2);
  reg [31:0] registers[31:0];

  always @(posedge clk)
    if (wenable) registers[waddr] <= wdata;

  assign rdata1 = (raddr1 != 0) ? registers[raddr1] : 0;
  assign rdata2 = (raddr2 != 0) ? registers[raddr2] : 0;
endmodule

module dmem(input  wire clk,   wenable,
            input  wire [31:0] addr, 
            input  wire [31:0] wdata,
            output wire [31:0] rdata);
  parameter MEM_SIZE = 64;
  reg [31:0] mem[MEM_SIZE-1:0];

  integer i;
  initial begin
    for(i = 0; i < MEM_SIZE; i = i+1) 
      mem[i] = 0;
    mem[2] = 1;
  end

  assign rdata = mem[addr];
  
  always @(posedge clk)
    if (wenable) mem[addr] <= wdata;
endmodule

module pcreg(input wire clk, reset,
             input wire [31:0] d,
             output reg [31:0] q);
  always @(posedge clk or posedge reset)
    if (reset)
      q <= 0;
    else
      q <= d;
endmodule

module alu(input  wire [2:0]  control,
           input  wire [31:0] a, b,
           output wire [31:0] result,
           output wire zeroflag);
  assign result = a + b;
endmodule

module signex(input  wire [15:0] in,
              output wire [31:0] out);
  assign out = {{16{in[15]}}, in};
endmodule

/*

module instr_mem_tb();
  reg  clk, reset;
  reg  [31:0] a;
  wire [31:0] rd;

  instr_mem dut(a, rd);

  initial begin
    clk = 0;
    a = 0;
    forever begin
      #5; clk = ~clk;
    end
  end

  initial begin
    $dumpfile("instr_mem.vcd");
    $dumpvars(0, instr_mem_tb);
    $monitor("rd = %b", rd);

    @(posedge clk);
    a = 1;
    @(posedge clk);
    a = 2;

    $finish;
  end
endmodule

module pcreg_tb();
  reg  clk, reset;
  reg  [7:0] d;
  wire [7:0] q;

  pcreg dut(clk, reset, d, q);

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
    $dumpvars(0, pcreg_tb);
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
*/
/*
module testbench();
  reg clk, reset;
  reg a, b, c, yexpected;
  wire y;
  reg[31:0] vectornum, errors;
  reg[3:0]  testvectors[10000:0];

  // instantiate device under test
  sillyfunction dut(.a(a), .b(b), .c(c), .y(y) );

  // generate clock
  always     // no sensitivity list, so it always executes
    begin
      clk = 1; #5; clk = 0; #5; // 10ns period
    end

  initial
    begin
      $display("--------------------------");
      $display("Loading testvectors");
      $display("--------------------------");
      $readmemb("example.tv", testvectors); // Read vectors
      vectornum = 0; errors = 0;
      reset = 1; #27; reset = 0;

      $display("--------------------------");
      $display("Running testbench");
      $display("--------------------------");
    end

  always @(posedge clk)
    begin
      #1; {a, b, c, yexpected} = testvectors[vectornum];
    end

  always @(negedge clk)
    if (!reset)
    begin
      if (y !== yexpected)
      begin
        $display("Error: input = %b", {a, b, c});
        $display("       expected = %b", yexpected);
        $display("       actual = %b", y);
        errors = errors + 1;
      end

      vectornum = vectornum + 1;
      if (testvectors[vectornum] === 4'bx)
      begin
        $display("--------------------------");
        $display("%d tests completed", vectornum);
        $display("%d error(s)", errors);
        $display("--------------------------");
        $finish;
      end
    end
endmodule
*/