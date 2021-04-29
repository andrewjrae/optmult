`timescale 1 ps / 1 ps

module mult_tb
  #(
    parameter D_W = 8,
    parameter TOP = 100
    // parameter TOP = 10
   )
  (
    output reg  [2*D_W-1:0] result
  );

  localparam CNTR_SIZE = $clog2(TOP)?$clog2(TOP):1;

  reg clk = 0;
  reg rst;
  wire [CNTR_SIZE-1:0] pixel;
  wire [CNTR_SIZE-1:0] slice;
  wire [D_W-1:0] in_a;
  wire [D_W-1:0] in_b;
  wire [D_W-1:0] out_a;
  wire [D_W-1:0] out_b;
  wire [2*D_W-1:0] mult;
  wire [(D_W - CNTR_SIZE)-1:0] zeros;

  counter#
  (
    .WIDTH  (TOP),
    .HEIGHT (TOP)
  )
  counter_B
  (
    .clk                  (clk),
    .rst                  (rst),
    .enable_row_count     (1'b1),
    .pixel_cntr           (pixel),
    .slice_cntr           (slice)
  );

  shit_reg #(.REG_W(D_W), .PIP_D(3))
    pipe_a (
      .clk(clk),
      .rst(rst),
      .in(in_a),
      .out(out_a));

  shit_reg #(.REG_W(D_W), .PIP_D(3))
    pipe_b (
      .clk(clk),
      .rst(rst),
      .in(in_b),
      .out(out_b));

  assign zeros = 0;
  assign in_a = { zeros, slice };
  assign in_b = { zeros, pixel };

  // optmult #(.UNSIGNED(1), .N_W(D_W), .M_W(D_W))
  optmult #()
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

`ifndef XIL_TIMING
  always #50000 clk = !clk;
`else
  always #50000 clk = !clk;
`endif

  always @(posedge clk) begin
    result <= mult;
    $display("%d * %d = %d", out_a, out_b, mult);
  end

  wire last_a;
  wire done;
  assign last_a = in_a == TOP-1;
  shit_reg #(.REG_W(1), .PIP_D(3))
    pipe_done (
      .clk(clk),
      .rst(rst),
      .in(last_a),
      .out(done));
  always @(posedge clk) begin
    if (done) $finish;
    // if (mult != out_a*out_b) $finish;
    // #202 $finish;
  end

endmodule // mult_tb

module shit_reg
  #(
    parameter REG_W = 1,
    parameter PIP_D = 1
   )
   (
    input wire                clk,
    input wire                rst,
    input wire  [REG_W-1:0]   in,
    output wire [REG_W-1:0]   out
   );

  localparam LENGTH = PIP_D*REG_W;

  reg [LENGTH-1:0]     pipe;
  assign out = pipe[REG_W-1:0];

  always @(posedge clk) begin
    if (rst) begin
      pipe <= {LENGTH{1'b0}};
    end else begin
      if (PIP_D > 1) begin
        pipe <= pipe >> REG_W;
      end
      pipe[LENGTH-1:(PIP_D-1)*REG_W] <= in;
    end
  end
endmodule // pipe_reg_d
