`timescale 1ns / 1ps
`default_nettype none
module CoreWrapper (
		input wire clk,
		input wire rst_n,
		output wire uart_tx,
		input wire uart_rx,
		output wire finished
    );

	////////////////////
	// Bus interface //
	//////////////////
	wire [31:0] arb_requests, arb_grants;

	wire [31:0] bus_addrData;
	wire bus_beginTransaction;
	wire bus_endTransaction;
	wire bus_error;
	wire bus_busy;
	wire [7:0] bus_burstSize;
	wire bus_readNWrite;
	wire bus_dataValid;
	wire [3:0] bus_byteEnables;

	///////////////////
	// Bluespec CPU //
	/////////////////
	wire reqValid;
	wire reqReady;
	wire reqWr;
	wire [31:0]reqAddr;
	wire [31:0]reqData;
	wire [31:0]respData;
	wire respValid;
	wire respReady;

	mkTopCore iCORE (
		.CLK(clk),
		.RST_N(rst_n),
		.EN_getBusReq(reqReady),
		.getBusReq({reqAddr, reqData, reqWr}),
		.RDY_getBusReq(reqValid),
		
		.putBusResp_resp(respData),
		.EN_putBusResp(respValid),
		.RDY_putBusResp(respReady),
		.getFinished(finished)
	);

	/////////////////////
	// CPU bus master //
	///////////////////
	wire cpu_arb_request;
	wire cpu_arb_grant;
	wire [31:0]  cpu_out_addrData;
	wire [3:0]   cpu_out_byteEnables;
	wire [7:0]   cpu_out_burstSize;
	wire         cpu_out_readNWrite;
	wire         cpu_out_beginTransaction;
	wire         cpu_out_endTransaction;
	wire         cpu_out_dataValid;
	wire         cpu_out_busy;

	CpuBusMaster iCPU_MASTER (
		.clk(clk),
		.rst_n(rst_n),
		.reqValid(reqValid),
		.reqReady(reqReady),
		.reqWr(reqWr),
		.reqAddr(reqAddr),
		.reqData(reqData),
		.respData(respData),
		.respValid(respValid),
		.respReady(respReady),
		.bus_arb_request_o(cpu_arb_request),
		.bus_arb_grant_i(cpu_arb_grant),
		.bus_mst_addrData_o(cpu_out_addrData),
		.bus_mst_byteEnables_o(cpu_out_byteEnables),
		.bus_mst_burstSize_o(cpu_out_burstSize),
		.bus_mst_readNWrite_o(cpu_out_readNWrite),
		.bus_mst_beginTransaction_o(cpu_out_beginTransaction),
		.bus_mst_endTransaction_o(cpu_out_endTransaction),
		.bus_mst_dataValid_o(cpu_out_dataValid),
		.bus_mst_busy_o(cpu_out_busy),
		.bus_addrData_i(bus_addrData),
		.bus_dataValid_i(bus_dataValid),
		.bus_endTransaction_i(bus_endTransaction),
		.bus_busy_i(bus_busy),
		.bus_error_i(bus_error)
	);

	////////////
	// SPART //
	//////////
	wire [31:0] spart_out_addrData;
	wire spart_out_endTransaction;
	wire spart_out_dataValid;
	wire spart_out_busy;
	wire spart_out_error;

	spart iSPART (
		.clk(clk),
		.rst_n(rst_n),
		.bus_addrData_i(bus_addrData),
		.bus_byteEnables_i(bus_byteEnables),
		.bus_burstSize_i(bus_burstSize),
		.bus_readNWrite_i(bus_readNWrite),
		.bus_beginTransaction_i(bus_beginTransaction),
		.bus_endTransaction_i(bus_endTransaction),
		.bus_dataValid_i(bus_dataValid),
		.bus_addrData_o(spart_out_addrData),
		.bus_endTransaction_o(spart_out_endTransaction),
		.bus_dataValid_o(spart_out_dataValid),
		.bus_busy_o(spart_out_busy),
		.bus_error_o(spart_out_error),
		.TX(uart_tx),
		.RX(uart_rx)
	);

	//////////////////
	// Connect bus //
	////////////////
	assign cpu_arb_grant = 1'b1;
	assign bus_addrData = cpu_out_addrData | spart_out_addrData;
	assign bus_beginTransaction = cpu_out_beginTransaction;
	assign bus_endTransaction = cpu_out_endTransaction | spart_out_endTransaction;
	assign bus_error = spart_out_error;
	assign bus_busy = cpu_out_busy | spart_out_busy;
	assign bus_burstSize = cpu_out_burstSize;
	assign bus_readNWrite = cpu_out_readNWrite;
	assign bus_dataValid = cpu_out_dataValid | spart_out_dataValid;
	assign bus_byteEnables = cpu_out_byteEnables;
endmodule

module CpuBusMaster (
	input wire clk,
	input wire rst_n, 
	// bluespec interface
	input wire reqValid,
	output wire reqReady,
	input wire reqWr,
	input wire [31:0]reqAddr,
	input wire [31:0]reqData,
	output wire [31:0]respData,

	output wire respValid,
	input wire respReady,
	// bus interface
	output wire       bus_arb_request_o,
    input wire        bus_arb_grant_i,
	output wire[31:0] bus_mst_addrData_o,
	output wire[3:0]  bus_mst_byteEnables_o,
	output wire[7:0]  bus_mst_burstSize_o,
	output wire       bus_mst_readNWrite_o,
	output wire       bus_mst_beginTransaction_o,
	output wire       bus_mst_endTransaction_o,
	output wire       bus_mst_dataValid_o,
	output wire       bus_mst_busy_o,
	input wire[31:0]  bus_addrData_i,
	input wire        bus_dataValid_i,
	input wire        bus_endTransaction_i,
	input wire        bus_busy_i,
	input wire        bus_error_i
);

localparam [3:0] IDLE       = 3'h0;
localparam [3:0] READ_REQ   = 3'h1;
localparam [3:0] READ_ADDR  = 3'h2;
localparam [3:0] READ_DATA  = 3'h3;
localparam [3:0] READ_RESP  = 3'h4;
localparam [3:0] WRITE_REQ  = 3'h5;
localparam [3:0] WRITE_ADDR = 3'h6;
localparam [3:0] WRITE_DATA = 3'h7;

reg bus_arb_request_r;
reg [31:0] bus_mst_addrData_r;
reg [3:0] bus_mst_byteEnables_r;
reg [7:0] bus_mst_burstSize_r;
reg bus_mst_readNWrite_r;
reg bus_mst_beginTransaction_r;
reg bus_mst_endTransaction_r;
reg bus_mst_dataValid_r;

reg bus_arb_request_rw;
reg [31:0] bus_mst_addrData_rw;
reg [3:0] bus_mst_byteEnables_rw;
reg [7:0] bus_mst_burstSize_rw;
reg bus_mst_readNWrite_rw;
reg bus_mst_beginTransaction_rw;
reg bus_mst_endTransaction_rw;
reg bus_mst_dataValid_rw;

reg [3:0] state_r;
reg [3:0] state_rw;

reg [31:0] data_r;
reg [31:0] data_rw;

reg [31:0] addr_r;
reg [31:0] addr_rw;

reg respValid_r;
reg respValid_rw;

always @(posedge clk) begin
	if (!rst_n) begin
		state_r <= IDLE;
		addr_r <= 0;
		data_r <= 0;
		respValid_r <= 0;
	end else begin
		state_r <= state_rw;
		addr_r <= addr_rw;
		data_r <= data_rw;
		respValid_r <= respValid_rw;
	end
end

always @(*) begin
	state_rw = state_r;
	data_rw = 0;
	addr_rw = 0;
	respValid_rw = 0;

	bus_arb_request_rw = 0;
	bus_mst_addrData_rw = 0;
	bus_mst_byteEnables_rw = 0;
	bus_mst_burstSize_rw = 0;
	bus_mst_readNWrite_rw = 0;
	bus_mst_beginTransaction_rw = 0;
	bus_mst_endTransaction_rw = 0;
	bus_mst_dataValid_rw = 0;

	case (state_r)
		IDLE: begin
			if (reqValid) begin
				addr_rw = reqAddr;
				data_rw = reqData;
				state_rw = reqWr ? READ_REQ : WRITE_REQ;
			end
		end
		READ_REQ: begin
			bus_arb_request_rw = 1'b1;
			state_rw = (bus_arb_grant_i & ~bus_busy_i) ? READ_ADDR : READ_REQ;
		end
		READ_ADDR: begin
			bus_mst_addrData_rw = addr_r;
			bus_mst_burstSize_rw = 8'h1;
			bus_mst_byteEnables_rw = 4'hF;
			bus_mst_readNWrite_rw = 1'b1;
			bus_mst_beginTransaction_rw = 1'b1;
			state_rw = bus_busy_i ? READ_ADDR : READ_DATA;
		end
		READ_DATA: begin
			if (bus_dataValid_i) begin
				data_rw = bus_addrData_i;
			end
			state_rw = bus_endTransaction_i ? IDLE : WRITE_DATA;
		end
		READ_RESP: begin
			// TODO: unsure if bluespec wants me to wait for the ready signal to be asserted before
			// I assert my go or enable signal.
			respValid_rw = 1'b1;
			state_rw = respReady ? IDLE : READ_RESP;
		end
		WRITE_REQ: begin
			bus_arb_request_rw = 1'b1;
			state_rw = (bus_arb_grant_i & ~bus_busy_i) ? WRITE_ADDR : WRITE_REQ;
		end
		WRITE_ADDR: begin
			bus_mst_addrData_rw = addr_r;
			bus_mst_burstSize_rw = 8'h1;
			bus_mst_byteEnables_rw = 4'hF;
			bus_mst_readNWrite_rw = 1'b0;
			bus_mst_beginTransaction_rw = 1'b1;
			state_rw = bus_busy_i ? WRITE_ADDR : WRITE_DATA;
		end
		WRITE_DATA: begin
			bus_mst_addrData_rw = data_r;
			bus_mst_dataValid_rw = 1'b1;
			bus_mst_endTransaction_rw = ~bus_busy_i;
			state_rw = bus_busy_i ? WRITE_DATA : IDLE;
		end
	endcase
end

always @(posedge clk) begin
	bus_arb_request_r <= bus_arb_request_rw;
	bus_mst_addrData_r <= bus_mst_addrData_rw;
	bus_mst_byteEnables_r <= bus_mst_byteEnables_rw;
	bus_mst_burstSize_r <= bus_mst_burstSize_rw;
	bus_mst_readNWrite_r <= bus_mst_readNWrite_rw;
	bus_mst_beginTransaction_r <= bus_mst_beginTransaction_rw;
	bus_mst_endTransaction_r <= bus_mst_endTransaction_rw;
	bus_mst_dataValid_r <= bus_mst_dataValid_rw;
end

assign reqReady = (state_r != IDLE);
assign respData = data_r;
assign respValid = respValid_r;
endmodule

`default_nettype wire