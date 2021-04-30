`timescale 1 ps / 1 ps

module mult_tb
  #(
    parameter D_W = 8,
    parameter END = 100,
    parameter SIGNED = 0
   )
  (
    output reg  [2*D_W-1:0] result
  );

  reg clk = 0;
  reg rst;
  wire [D_W-1:0] in_a;
  wire [D_W-1:0] in_b;
  wire [D_W-1:0] out_a;
  wire [D_W-1:0] out_b;
  wire [2*D_W-1:0] mult;

  pipe_reg #(.REG_W(D_W), .PIP_D(3))
    pipe_a (
      .clk(clk),
      .rst(rst),
      .in(in_a),
      .out(out_a));

  pipe_reg #(.REG_W(D_W), .PIP_D(3))
    pipe_b (
      .clk(clk),
      .rst(rst),
      .in(in_b),
      .out(out_b));

  assign in_a = 0;
  assign in_b = 0;

  optmult #(.UNSIGNED(1), .N_W(D_W), .M_W(D_W))
    mult_inst (
      .clk(clk),
      .rst(rst),
      .a(in_a),
      .b(in_b),
      .out(mult)
    );

  initial begin
    rst = 1'b1;
  end

  always @(posedge clk) begin
    rst <= rst>>1;
  end

  always @(posedge clk) begin
    result <= mult;
    $display("%d * %d = %d", out_a, out_b, mult);
  end

  wire last_a;
  wire done;
  assign last_a = in_a == END-1;
  pipe_reg #(.REG_W(1), .PIP_D(3))
    pipe_done (
      .clk(clk),
      .rst(rst),
      .in(last_a),
      .out(done));
  always @(posedge clk) begin
    if (done) $finish;
    if (mult != out_a*out_b) $finish;
    if (mult != out_a*out_b) $finish;
  end

endmodule // mult_tb
