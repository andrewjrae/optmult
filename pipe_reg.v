`timescale 1ps / 1ps

module pipe_reg
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
