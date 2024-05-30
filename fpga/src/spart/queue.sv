module queue (
   input         clk,
   input         enable,
   input  [2:0]  raddr,
   input  [2:0]  waddr,
   input  [7:0]  wdata,
   output [7:0]  rdata
);
   
   reg [7:0] mem [7:0];
   reg [7:0] rdata_r;

   integer i;

   initial begin
      for (i = 0; i < 8; i += 1) begin
         mem[i] = 8'h0;
      end
   end

   // Intel HDL Coding Styles, 14.1.7 "Simple Dual-Port, Dual-Clock Synchronous RAM"
   // Queue reads and writes on negedge because it is subject to the same timing
   // requirements as the data/instruction memory (being a memory mapped peripheral.)
   always @(negedge clk) begin
      if (enable) begin
         mem[waddr] <= wdata;
      end
      rdata_r <= mem[raddr];
   end


   assign rdata = rdata_r;

endmodule