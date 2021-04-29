`timescale 1 ps / 1 ps

module XORCY
  (
   input  wire LI,
   input  wire CI,
   output wire O
  );

  assign O = LI ^ CI;

endmodule // XORCY
