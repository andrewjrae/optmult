`timescale 1 ps / 1 ps

// Highly optimized multiplier based off this paper:
// https://www.mdpi.com/2073-431X/5/4/20/pdf
// ** note this link immediately downloads the pdf **
module optmult_unclocked
  #(
    parameter UNSIGNED = 1,
    parameter M_W = 8,
    parameter N_W = 8
   )
   (
    input   wire    [M_W-1:0]       a,
    input   wire    [N_W-1:0]       b,
    output  wire    [N_W+M_W-1:0]     out
   );

  // M_W and N_W eXtended
  localparam N_ODD = N_W % 2 == 1;
  localparam NX = N_ODD ? N_W + 1 : N_W + 2*UNSIGNED;
  localparam MX = UNSIGNED ? M_W + 1 : M_W;
  localparam RHO = NX/2;
  // $info("N_ODD: %d, NX: %D, MX %d, RHO: %d", N_ODD, NX, MX, RHO);

  // extended a and b
  wire    [MX-1:0]                A;
  wire    [NX-1:0]                B;

  // interconnect wires
  wire    [MX+1:0]                x  [RHO-1:0];
  wire    [MX-1:0]                p  [RHO-1:0];
  wire    [MX:0]                  np [RHO-1:0];
  wire    [MX:0]                  c  [RHO-1:0];
  wire    [RHO-1:0]               f;

  // full output, will try to cut off bits that I don't need
  // though they may very well get optimized away
  wire    [NX+MX-1:0]             P;

  genvar i;
  genvar rho;
  generate
    // extend the inputs to their required size
    if (UNSIGNED) begin
      assign A = {1'b0, a};
      if (N_ODD) begin
        assign B = {1'b0, b};
      end else begin
        assign B = {2'b0, b};
      end
    end else begin
      assign A = a;
      if (N_ODD) begin
        assign B = {b[N_W-1], b};
      end else begin
        assign B = b;
      end
    end

    // gen loop
    for (rho = 0; rho < RHO; rho = rho + 1) begin
      for (i = 0; i <= MX; i = i + 1) begin
        // --------------------------- //
        // ***** START FIRST ROW ***** //
        // --------------------------- //
        if (rho == 0) begin
          if (i == 0) begin
            LUT6_2 #(.INIT(64'h0CCA533FF335ACC0))
              lut (
                .I0(1'b0),
                .I1(A[i]),
                .I2(1'b0),
                .I3(B[2*rho]),
                .I4(B[2*rho+1]),
                .I5(1'b0),
                .O5(p[rho][i]),
                .O6(np[rho][i])
              );
            MUXCY muxc (.DI(p[rho][i]), .CI(B[1]), .S(np[rho][i]), .O(c[rho][i]));
            XORCY xorc (.LI(np[rho][i]), .CI(B[1]), .O(x[rho][i]));
          end else if (i == MX) begin
            // final column LUT6_2
            LUT6_2 #(.INIT(64'h5999666A0CCC333F))
              lut (
                .I0(1'b0),
                .I1(A[i-1]),
                .I2(1'b0),
                .I3(B[2*rho]),
                .I4(B[2*rho+1]),
                .I5(1'b1),
                .O5(np[rho][i]),
                .O6(f[rho])
              );
            MUXCY muxc (.DI(np[rho][i]), .CI(c[rho][i-1]), .S(f[rho]), .O(c[rho][i]));
            XORCY xorc (.LI(f[rho]), .CI(c[rho][i-1]), .O(x[rho][i]));
            XORCY xorcx (.LI(1'b1), .CI(c[rho][i]), .O(x[rho][i+1]));
          end else begin
            LUT6_2 #(.INIT(64'h0CCA533FF335ACC0))
              lut (
                .I0(A[i-1]),
                .I1(A[i]),
                .I2(1'b0),
                .I3(B[2*rho]),
                .I4(B[2*rho+1]),
                .I5(1'b0),
                .O5(p[rho][i]),
                .O6(np[rho][i])
              );
            MUXCY muxc (.DI(p[rho][i]), .CI(c[rho][i-1]), .S(np[rho][i]), .O(c[rho][i]));
            XORCY xorc (.LI(np[rho][i]), .CI(c[rho][i-1]), .O(x[rho][i]));
          end
        // -------------------------- //
        // ***** START ROW LOOP ***** //
        // -------------------------- //
        end else begin
          if (i == 0) begin
            LUT6_2 #(.INIT(64'h0CCA533FF335ACC0))
              lut (
                .I0(1'b0),
                .I1(A[i]),
                .I2(B[2*rho-1]),
                .I3(B[2*rho]),
                .I4(B[2*rho+1]),
                .I5(x[rho-1][i+2]),
                .O5(p[rho][i]),
                .O6(np[rho][i])
              );
            MUXCY muxc (.DI(p[rho][i]), .CI(B[2*rho+1]), .S(np[rho][i]), .O(c[rho][i]));
            XORCY xorc (.LI(np[rho][i]), .CI(B[2*rho+1]), .O(x[rho][i]));
          end else if (i == MX) begin
            // final column LUT6_2
            LUT6_2 #(.INIT(64'h5999666A0CCC333F))
              lut (
                .I0(x[rho-1][i+1]),
                .I1(A[i-1]),
                .I2(B[2*rho-1]),
                .I3(B[2*rho]),
                .I4(B[2*rho+1]),
                .I5(1'b1),
                .O5(np[rho][i]),
                .O6(f[rho])
              );
            MUXCY muxc (.DI(np[rho][i]), .CI(c[rho][i-1]), .S(f[rho]), .O(c[rho][i]));
            XORCY xorc (.LI(f[rho]), .CI(c[rho][i-1]), .O(x[rho][i]));
            XORCY xorcx (.LI(1'b1), .CI(c[rho][i]), .O(x[rho][i+1]));
          end else begin
            // standard LUT6_2
            LUT6_2 #(.INIT(64'h0CCA533FF335ACC0))
              lut (
                .I0(A[i-1]),
                .I1(A[i]),
                .I2(B[2*rho-1]),
                .I3(B[2*rho]),
                .I4(B[2*rho+1]),
                .I5(x[rho-1][i+2]),
                .O5(p[rho][i]),
                .O6(np[rho][i])
              );
            MUXCY muxc (.DI(p[rho][i]), .CI(c[rho][i-1]), .S(np[rho][i]), .O(c[rho][i]));
            XORCY xorc (.LI(np[rho][i]), .CI(c[rho][i-1]), .O(x[rho][i]));
          end
        end
      end
    end

    // assign output wires
    for (rho = 0; rho < RHO; rho = rho + 1) begin
      assign P[2*rho] = x[rho][0];
      assign P[2*rho+1] = x[rho][1];
    end
    for (i = 0; i < MX; i = i + 1) begin
      assign P[i+NX] = x[RHO-1][i+2];
    end
  endgenerate

  assign out = P[N_W+M_W-1:0];

endmodule // optmult
