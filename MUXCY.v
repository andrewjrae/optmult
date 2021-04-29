`timescale 1 ps / 1 ps

module MUXCY
  (
   input  wire DI,
   input  wire CI,
   input  wire S,
   output wire O
  );

  assign O = S ? CI : DI;

endmodule // MUXCY
