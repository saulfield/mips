`timescale 1us/1ns

// ==========================================================================
// Testbench
// ==========================================================================

module mips_testbench();
  reg  clk, reset;
  wire [31:0] pc;

  mips_cpu dut(clk, reset, pc);

  always begin
    clk <= 1; #5; clk <= 0; #5;
  end

  initial begin
    $dumpfile("mips_testbench.vcd");
    $dumpvars(0, mips_testbench);
    // $monitor("rd = %b", rd);

    reset <= 1;

    @(negedge clk);
    reset <= 0;

    @(posedge clk);
    @(posedge clk);
    @(posedge clk);
    @(posedge clk);
    begin
      if(dut.datapath.regfile.registers[10] === 4 && dut.datapath.dmem.mem[2] === 4) begin
        $display("Simulation succeeded");
      end
      else begin
        $display("Simulation failed");
      end
    end
    $finish;
  end
endmodule

// ==========================================================================
// Top
// ==========================================================================

module mips_cpu(input         clk,
                input         reset,
                output [31:0] pc);
  
  // control signals
  wire [2:0]  alu_ctrl;
  wire        reg_wsrc;
  wire        mem_write;
  wire        branch;
  wire        alu_src;
  wire        reg_dest;
  wire        reg_write;

  // misc.
  wire [31:0] instr;

  imem imem(pc[7:2], instr);

  control control(
    .opcode     (instr[31:26]),
    .funct      (instr[5:0]),
    .alu_ctrl   (alu_ctrl),
    .reg_wsrc   (reg_wsrc),
    .mem_write  (mem_write),
    .branch     (branch),
    .alu_src    (alu_src),
    .reg_dest   (reg_dest),
    .reg_write  (reg_write)
  );

  datapath datapath(
    .clk        (clk),
    .reset      (reset),
    .alu_ctrl   (alu_ctrl),
    .reg_wsrc   (reg_wsrc),
    .mem_write  (mem_write),
    .branch     (branch),
    .alu_src    (alu_src),
    .reg_dest   (reg_dest),
    .reg_write  (reg_write),
    .instr      (instr),
    .pc         (pc)
  );

endmodule

// ==========================================================================
// Datapath
// ==========================================================================

module datapath(input         clk,
                input         reset,
                input  [2:0]  alu_ctrl,
                input         reg_wsrc,
                input         mem_write,
                input         branch,
                input         alu_src,
                input         reg_dest,
                input         reg_write,
                input  [31:0] instr,
                output [31:0] pc);

  wire [4:0] reg_waddr;
  wire [31:0] reg_rdata1, reg_rdata2;
  wire [31:0] reg_wdata;
  wire [31:0] sign_imm;
  wire [31:0] mem_rdata;
  wire [31:0] pc_plus4;
  wire [31:0] pc_next;
  wire [31:0] pc_branch;
  wire [31:0] alu_in2;
  wire [31:0] alu_result;
  wire [31:0] sign_imm_sl2;
  wire pc_src;
  wire zero_flag;

  // pc
  and2       pcsrc_and(branch, zero, pc_src);
  mux2 #(32) pcsrc_mux(pc_src, pc_plus4, pc_branch, pc_next);
  pcreg      pcreg(clk, reset, pc_next, pc);
  adder      pcadd4(pc, 4, pc_plus4);
  sl2        pcsl2(sign_imm, sign_imm_sl2);
  adder      pcaddbranch(sign_imm_sl2, pc_plus4, pc_branch);

  // registers, ALU, memory
  regfile    regfile(clk, reg_write,
                     reg_waddr, reg_wdata,
                     instr[25:21], reg_rdata1,
                     instr[20:16], reg_rdata2);
  mux2 #(5)  regdst_mux(reg_dest, instr[20:16], instr[15:11], reg_waddr);
  signex     signex(instr[15:0], sign_imm);
  mux2 #(32) alu_in2_mux(alu_src, reg_rdata2, sign_imm, alu_in2);
  alu        alu(alu_ctrl,
                 reg_rdata1, alu_in2,
                 alu_result, zero_flag);
  dmem       dmem(clk, mem_write,
                  alu_result, reg_rdata2, 
                  mem_rdata);
  mux2 #(32) reg_wdata_mux(reg_wsrc, alu_result, mem_rdata, reg_wdata);
endmodule

module imem(input  [5:0] addr,
            output [31:0] rdata);
  reg [31:0] mem[63:0];

  initial
    $readmemb("code.dat", mem);

  assign rdata = mem[addr];
endmodule

module dmem(input  clk,   wenable,
            input  [31:0] addr, 
            input  [31:0] wdata,
            output [31:0] rdata);
  parameter MEM_SIZE = 64;
  reg [31:0] mem[MEM_SIZE-1:0];

  integer i;
  initial begin
    for(i = 0; i < MEM_SIZE; i = i+1) 
      mem[i] <= 0;
    // mem[0] <= 0;
    mem[1] <= 4;
    // mem[2] <= 2;
  end

  assign rdata = mem[addr];
  
  always @(posedge clk)
    if (wenable) mem[addr] <= wdata;
endmodule

module and2(input  a, b,
            output y);
  assign y = a & b;
endmodule

module sl2(input  [31:0] in,
           output [31:0] out);
  assign out = {in[29:0], 2'b00};
endmodule

module regfile(input  clk,   wenable,
               input  [4:0]  waddr,
               input  [31:0] wdata,
               input  [4:0]  raddr1, 
               output [31:0] rdata1,
               input  [4:0]  raddr2,
               output [31:0] rdata2);
  reg [31:0] registers[31:0];

  always @(posedge clk)
    if (wenable) registers[waddr] <= wdata;

  assign rdata1 = (raddr1 != 0) ? registers[raddr1] : 0;
  assign rdata2 = (raddr2 != 0) ? registers[raddr2] : 0;
endmodule

module pcreg(input  clk, reset,
             input  [31:0] d,
             output reg [31:0] q);
  always @(posedge clk or posedge reset)
    if (reset)
      q <= 0;
    else
      q <= d;
endmodule

module adder(input  [31:0] a, b,
             output [31:0] y);
  assign y = a + b;
endmodule

module alu(input  [2:0]  control,
           input  [31:0] a, b,
           output [31:0] result,
           output zeroflag);
  assign result = a + b;
endmodule

module signex(input  [15:0] in,
              output [31:0] out);
  assign out = {{16{in[15]}}, in};
endmodule

module mux2 #(parameter WIDTH = 8)
             (input  s,
              input  [WIDTH-1:0] a, b,
              output [WIDTH-1:0] y);
  assign y = s ? b : a;
endmodule

// ==========================================================================
// Control
// ==========================================================================

module control(input  [5:0] opcode,
               input  [5:0] funct,
               output [2:0] alu_ctrl,
               output       reg_wsrc,
               output       mem_write,
               output       branch,
               output       alu_src,
               output       reg_dest,
               output       reg_write);
  wire [1:0] alu_op;

  main_decoder main_decoder(
    .opcode   (opcode),
    .alu_op   (alu_op),
    .reg_wsrc (reg_wsrc),
    .mem_write(mem_write),
    .branch   (branch),
    .alu_src  (alu_src),
    .reg_dest (reg_dest),
    .reg_write(reg_write)
  );

  alu_decoder alu_decoder(
    .funct    (funct),
    .alu_op   (alu_op),
    .alu_ctrl (alu_ctrl)
  );
endmodule

module main_decoder(input  [5:0] opcode,
                    output [1:0] alu_op,
                    output       reg_wsrc,
                    output       mem_write,
                    output       branch,
                    output       alu_src,
                    output       reg_dest,
                    output       reg_write);
  reg [7:0] controls;
  assign {reg_write, reg_dest, alu_src, branch, mem_write, reg_wsrc, alu_op}
    = controls;

  always @(*) begin
    case (opcode)
      6'b000000: controls <= 8'b11000010; // R-type
      6'b100011: controls <= 8'b10100100; // lw
      6'b101011: controls <= 8'b0x101x00; // se
      6'b000100: controls <= 8'b0x010x01; // beq
      default: controls <= 8'bxxxxxxxx;
    endcase
  end
endmodule

module alu_decoder(input  [5:0] funct,
                   input  [1:0] alu_op,
                   output [2:0] alu_ctrl);
  reg [2:0] alu_ctrl;

  always @(*) begin
    case (alu_op)
      2'b00: alu_ctrl <= 3'b010;
      2'b01: alu_ctrl <= 3'b110;
      default: case (funct)
        6'b100000: alu_ctrl <= 3'b010;
        6'b100010: alu_ctrl <= 3'b110;
        6'b100100: alu_ctrl <= 3'b000;
        6'b100101: alu_ctrl <= 3'b001;
        6'b101010: alu_ctrl <= 3'b111;
        default: alu_ctrl <= 3'bxxx;
      endcase
    endcase
  end
endmodule

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