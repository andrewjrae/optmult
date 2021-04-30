`timescale 1 ps / 1 ps

// Highly optimized multiplier based off this paper:
// https://www.mdpi.com/2073-431X/5/4/20/pdf
// ** note this link immediately downloads the pdf **
module optmult
  #(
    parameter UNSIGNED = 1,
    parameter M_W = 8,
    parameter N_W = 8
   )
   (
    input wire                clk,
    input wire                rst,
    input wire  [M_W-1:0]     a,
    input wire  [N_W-1:0]     b,
    output wire [N_W+M_W-1:0] out
   );

  // M_W and N_W eXtended
  localparam N_ODD = N_W % 2 == 1;
  localparam NX = N_ODD ? N_W + 1 : N_W + 2*UNSIGNED;
  localparam MX = UNSIGNED ? M_W + 1 : M_W;
  localparam RHO = NX/2;
  localparam NUM_PIPES = (RHO+1)/2;

  // extended a and b
  wire    [MX-1:0]                A [RHO-1:0];
  wire    [NX-1:0]                B [RHO-1:0];

  // interconnect wires
  wire    [MX+1:0]                x_in  [RHO-1:0];
  wire    [MX+1:0]                x_out [RHO-1:0];
  wire    [MX:0]                  c_in  [RHO-1:0];
  wire    [MX-1:0]                c_out [RHO-1:0];

  // full output, will try to cut off bits that I don't need
  // though they may very well get optimized away
  wire    [NX+MX-1:0]             P;

  genvar i;
  genvar rho;
  generate
    // extend the inputs to their required size
    if (UNSIGNED) begin
      assign A[0] = {1'b0, a};
      if (N_ODD) begin
        assign B[0] = {1'b0, b};
      end else begin
        assign B[0] = {2'b0, b};
      end
    end else begin
      assign A[0] = a;
      if (N_ODD) begin
        assign B[0] = {b[N_W-1], b};
      end else begin
        assign B[0] = b;
      end
    end

    // map intermediate wires
    for (rho = 0; rho < RHO; rho = rho + 1) begin
      for (i = 1; i < MX+1; i = i + 1) begin
        assign c_in[rho][i] = c_out[rho][i-1];
      end
    end
    // assign the outs and ins
    assign x_in[0] = {(MX+2){1'b0}};
    for (rho = 1; rho < RHO; rho = rho + 1) begin
      if (rho % 2 == 0) begin
        pipe_reg #(.REG_W(MX+2), .PIP_D(1))
          pipe_x (
            .clk(clk),
            .rst(rst),
            .in(x_out[rho-1]),
            .out(x_in[rho]));
        pipe_reg #(.REG_W(MX), .PIP_D(1))
          pipe_a (
            .clk(clk),
            .rst(rst),
            .in(A[rho-1]),
            .out(A[rho]));
        // pipe_reg #(.REG_W(NX), .PIP_D(1))
        pipe_reg #(.REG_W(NX-2*rho+1), .PIP_D(1))
          pipe_b (
            .clk(clk),
            .rst(rst),
            .in(B[rho-1][NX-1:2*rho-1]),
            .out(B[rho][NX-1:2*rho-1]));
        if (rho > 1) assign B[rho][2*rho-2:0] = 0;
        else assign B[rho][0] = 1'b0;
            // .in(B[rho-1]),
            // .out(B[rho]));
      end else begin
        assign x_in[rho] = x_out[rho-1];
        assign A[rho] = A[rho-1];
        assign B[rho] = B[rho-1];
      end
    end

    // always clock out the the output
    pipe_reg #(.REG_W(MX+2), .PIP_D(1))
      pipe_x (
        .clk(clk),
        .rst(rst),
        .in(x_out[RHO-1]),
        .out(P[NX+MX-1:NX-2]));

    for (rho = 1; rho < RHO; rho = rho + 1) begin
      pipe_reg #(.REG_W(2), .PIP_D(NUM_PIPES-rho/2))
        pipe_P (
          .clk(clk),
          .rst(rst),
          .in(x_in[rho][1:0]),
          .out(P[2*rho-1:2*rho-2]));
    end

    // gen loop for luts
    for (rho = 0; rho < RHO; rho = rho + 1) begin
      assign c_in[rho][0] = 1'b0;
      for (i = 0; i <= MX; i = i + 1) begin
        // -------------------------- //
        // ***** START ROW LOOP ***** //
        // -------------------------- //
        if (i == 0) begin
          // first column LUT6_2
          booth_unit #()
            booth (
              .I0(1'b0),
              .I1(A[rho][i]),
              .I2(rho != 0 ? B[rho][2*rho-1] : 1'b0),
              .I3(B[rho][2*rho]),
              .I4(B[rho][2*rho+1]),
              .I5(x_in[rho][i+2]),
              .c_in(B[rho][2*rho+1]),
              .c_out(c_out[rho][i]),
              .x_out(x_out[rho][i])
            );
        end else if (i == MX) begin
          // final column LUT6_2
          booth_unit_msb #()
            booth_msb (
              .I0(x_in[rho][i+1]),
              .I1(A[rho][i-1]),
              .I2(rho != 0 ? B[rho][2*rho-1] : 1'b0),
              .I3(B[rho][2*rho]),
              .I4(B[rho][2*rho+1]),
              .I5(1'b1),
              .c_in(c_in[rho][i]),
              .x_out0(x_out[rho][i]),
              .x_out1(x_out[rho][i+1])
            );
        end else begin
          // standard LUT6_2
          booth_unit #()
            booth (
              .I0(A[rho][i-1]),
              .I1(A[rho][i]),
              .I2(rho != 0 ? B[rho][2*rho-1] : 1'b0),
              .I3(B[rho][2*rho]),
              .I4(B[rho][2*rho+1]),
              .I5(x_in[rho][i+2]),
              .c_in(c_in[rho][i]),
              .c_out(c_out[rho][i]),
              .x_out(x_out[rho][i])
            );
        end
      end
    end
  endgenerate

  // assign the output to final pipe reg
  assign out = P[N_W+M_W-1:0];

endmodule // optmult

module booth_unit
  #(
   )
   (
    input wire                I0,
    input wire                I1,
    input wire                I2,
    input wire                I3,
    input wire                I4,
    input wire                I5,
    input wire                c_in,
    output wire               c_out,
    output wire               x_out
   );

  wire                        p;
  wire                        np;

  LUT6_2 #(.INIT(64'h0CCA533FF335ACC0))
    lut (
      .I0(I0),
      .I1(I1),
      .I2(I2),
      .I3(I3),
      .I4(I4),
      .I5(I5),
      .O5(p),
      .O6(np)
    );
  MUXCY muxc (.DI(p), .CI(c_in), .S(np), .O(c_out));
  XORCY xorc (.LI(np), .CI(c_in), .O(x_out));
endmodule // booth_unit

module booth_unit_msb
  #(
   )
   (
    input wire                I0,
    input wire                I1,
    input wire                I2,
    input wire                I3,
    input wire                I4,
    input wire                I5,
    input wire                c_in,
    output wire               x_out0,
    output wire               x_out1
   );

  wire                        f;
  wire                        np;
  wire                        c_out;

  LUT6_2 #(.INIT(64'h5999666A0CCC333F))
    lut (
      .I0(I0),
      .I1(I1),
      .I2(I2),
      .I3(I3),
      .I4(I4),
      .I5(I5),
      .O5(np),
      .O6(f)
    );
  MUXCY muxc (.DI(np), .CI(c_in), .S(f), .O(c_out));
  XORCY xorc (.LI(f), .CI(c_in), .O(x_out0));
  // MUXCY muxcx (.DI(1'b0), .CI(c_out), .S(1'b1), .O(c_out[rho][i+1]));
  XORCY xorcx (.LI(1'b1), .CI(c_out), .O(x_out1));
endmodule // booth_unit_msb
