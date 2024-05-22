module simpleMemSlave #(
    parameter [31: 0] baseAddr = 32'hDEADBEEF,
    parameter memSize = 512
) (
    input clk_i,
    input rst_i,

    // Slave Input
    input [31:0] bus_addrData_i,
    input [3:0] bus_byteEnables_i,
    input [7:0] bus_burstSize_i,
    input bus_readNWrite_i,
    input bus_beginTransaction_i,
    input bus_endTransaction_i,
    input bus_dataValid_i,

    // Slave Output
    output [31:0] bus_addrData_o,
    output bus_endTransaction_o,
    output bus_dataValid_o,
    output bus_busy_o,
    output bus_error_o
);

reg [31:0] mem [memSize-1:0];
integer i;
initial begin
    for (i = 0; i < memSize; i = i + 1) begin
        mem[i] = 0;
    end
end

reg [31:0] memAddr_r = 0;
reg go_r = 0;
reg rd_n_wr_r = 0;
reg [7:0] burstSize_r = 0;
reg [3:0] byteEnables_r = 0;

wire [31:0] baseAddr_calc = (bus_addrData_i - baseAddr) >> 2;

wire [31:0] byteEnables_mask = {{8{byteEnables_r[3]}},
    {8{byteEnables_r[2]}},
    {8{byteEnables_r[1]}},
    {8{byteEnables_r[0]}}};

wire isMyTransaction = (bus_addrData_i[31:25] == baseAddr[31:25]);

always @(posedge clk_i) begin
    if (rst_i) begin
        memAddr_r <= 0;
        go_r <= 0;
        rd_n_wr_r <= 0;
        burstSize_r <= 0;
        byteEnables_r <= 0;
    end else begin 
        memAddr_r <= go_r ? memAddr_r+1 : (bus_beginTransaction_i ? baseAddr_calc : 32'h0);
        go_r <= bus_beginTransaction_i ? isMyTransaction : (burstSize_r == 0 ? 1'b0 : go_r);
        burstSize_r <= bus_beginTransaction_i ? bus_burstSize_i : (burstSize_r - 1);
        byteEnables_r <= bus_beginTransaction_i ? bus_byteEnables_i : byteEnables_r;
        rd_n_wr_r <= bus_beginTransaction_i ? bus_readNWrite_i : rd_n_wr_r;
        if (go_r & ~rd_n_wr_r) begin
            mem[memAddr_r] <= (mem[memAddr_r] & ~byteEnables_mask) | (bus_addrData_i & byteEnables_mask);
        end
    end
end

assign bus_addrData_o = (go_r & rd_n_wr_r) ? (byteEnables_mask & mem[memAddr_r]) : 0;
assign bus_dataValid_o = go_r;
assign bus_endTransaction_o = (go_r & burstSize_r == 0);
assign bus_busy_o = 1'b0;
assign bus_error_o = 1'b0;
endmodule