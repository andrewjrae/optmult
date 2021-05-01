`timescale 1 ps / 1 ps

module mult_tb
  #(
    parameter M_W = 8,
    parameter N_W = 8
   )
  (input wire clk);

  reg rst;

  localparam N_ODD = N_W % 2 == 1;
`ifdef _UNSIGNED
  localparam NX = N_ODD ? N_W + 1 : N_W + 2;
`else
  localparam NX = N_ODD ? N_W + 1 : N_W;
`endif
  localparam NUM_PIPES = (NX/2+1)/2;

`ifdef _UNSIGNED
  reg [M_W-1:0] in_a;
  reg [N_W-1:0] in_b;
  wire unsigned [M_W-1:0] out_a;
  wire unsigned [N_W-1:0] out_b;
  wire unsigned [M_W+N_W-1:0] mult;
  reg  unsigned [M_W+N_W-1:0] result;
`else
  reg [M_W-1:0] in_a;
  reg [N_W-1:0] in_b;
  wire signed [M_W-1:0] out_a;
  wire signed [N_W-1:0] out_b;
  wire signed [M_W+N_W-1:0] mult;
  reg  signed [M_W+N_W-1:0] result;
`endif

  pipe_reg #(.REG_W(M_W), .PIP_D(NUM_PIPES))
    pipe_a (
      .clk(clk),
      .rst(rst),
      .in(in_a),
      .out(out_a));

  pipe_reg #(.REG_W(N_W), .PIP_D(NUM_PIPES))
    pipe_b (
      .clk(clk),
      .rst(rst),
      .in(in_b),
      .out(out_b));

`ifdef _UNSIGNED
  optmult #(.UNSIGNED(1), .N_W(N_W), .M_W(M_W))
`else
  optmult #(.UNSIGNED(0), .N_W(N_W), .M_W(M_W))
`endif
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
    if (rst) begin
      in_a <= {M_W{1'b0}};
      in_b <= {N_W{1'b0}};
    end else begin
      in_a <= in_a + { {(M_W-1){1'b0}}, in_b == {N_W{1'b1}}};
      in_b <= in_b + 1;
    end
  end

  always @(posedge clk) begin
    result <= mult;
    $display("%d * %d = %d", out_a, out_b, mult);
  end

`ifdef END
  wire done;
  assign done = out_a == `END-1;
`endif

  always @(posedge clk) begin
    if (mult != out_a*out_b) begin
      $display("ERROR: got %d * %d = %d, expected %d", out_a, out_b, mult, out_a*out_b);
      $finish;
    end
`ifdef END
    if (done) begin
      $display("Testbench completed successfully!");
      $finish;
    end
`endif
    if (out_a == {M_W{1'b1}} && out_b == {N_W{1'b1}}) begin
      $display("Testbench completed successfully!");
      $finish;
    end
  end

endmodule // mult_tb
