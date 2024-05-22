`timescale 1ns / 1ps
`default_nettype none
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/19/2024 11:40:12 PM
// Design Name: 
// Module Name: CoreWrapper
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module CoreWrapper #(
		// Width of M_AXI address bus. 
    // The master generates the read and write addresses of width specified as C_M_AXI_ADDR_WIDTH.
		parameter integer C_M_AXI_ADDR_WIDTH	= 32,
		// Width of M_AXI data bus. 
    // The master issues write data and accept read data where the width of the data bus is C_M_AXI_DATA_WIDTH
		parameter integer C_M_AXI_DATA_WIDTH	= 32
)(
		// AXI clock signal
		input wire  M_AXI_ACLK,
		// AXI active low reset signal
		input wire  M_AXI_ARESETN,
		// Master Interface Write Address Channel ports. Write address (issued by master)
		output wire [C_M_AXI_ADDR_WIDTH-1 : 0] M_AXI_AWADDR,
		// Write channel Protection type.
    	// This signal indicates the privilege and security level of the transaction,
    	// and whether the transaction is a data access or an instruction access.
		output wire [2 : 0] M_AXI_AWPROT,
		// Write address valid. 
	    // This signal indicates that the master signaling valid write address and control information.
		output wire  M_AXI_AWVALID,
		// Write address ready. 
	    // This signal indicates that the slave is ready to accept an address and associated control signals.
		input wire  M_AXI_AWREADY,
		// Master Interface Write Data Channel ports. Write data (issued by master)
		output wire [C_M_AXI_DATA_WIDTH-1 : 0] M_AXI_WDATA,
		// Write strobes. 
    	// This signal indicates which byte lanes hold valid data.
    	// There is one write strobe bit for each eight bits of the write data bus.
		output wire [C_M_AXI_DATA_WIDTH/8-1 : 0] M_AXI_WSTRB,
		// Write valid. This signal indicates that valid write data and strobes are available.
		output wire  M_AXI_WVALID,
		// Write ready. This signal indicates that the slave can accept the write data.
		input wire  M_AXI_WREADY,
		// Master Interface Write Response Channel ports. 
    	// This signal indicates the status of the write transaction.
		input wire [1 : 0] M_AXI_BRESP,
		// Write response valid. 
    	// This signal indicates that the channel is signaling a valid write response
		input wire  M_AXI_BVALID,
		// Response ready. This signal indicates that the master can accept a write response.
		output wire  M_AXI_BREADY,
		// Master Interface Read Address Channel ports. Read address (issued by master)
		output wire [C_M_AXI_ADDR_WIDTH-1 : 0] M_AXI_ARADDR,
		// Protection type. 
    	// This signal indicates the privilege and security level of the transaction, 
    	// and whether the transaction is a data access or an instruction access.
		output wire [2 : 0] M_AXI_ARPROT,
		// Read address valid. 
    	// This signal indicates that the channel is signaling valid read address and control information.
		output wire  M_AXI_ARVALID,
		// Read address ready. 
    	// This signal indicates that the slave is ready to accept an address and associated control signals.
		input wire  M_AXI_ARREADY,
		// Master Interface Read Data Channel ports. Read data (issued by slave)
		input wire [C_M_AXI_DATA_WIDTH-1 : 0] M_AXI_RDATA,
		// Read response. This signal indicates the status of the read transfer.
		input wire [1 : 0] M_AXI_RRESP,
		// Read valid. This signal indicates that the channel is signaling the required read data.
		input wire  M_AXI_RVALID,
		// Read ready. This signal indicates that the master can accept the read data and response information.
		output wire  M_AXI_RREADY,

		output wire finished
    );
	
	wire clk = M_AXI_ACLK;
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
		.RST_N(M_AXI_ARESETN),
		.EN_getBusReq(reqReady),
		.getBusReq({reqAddr, reqData, reqWr}),
		.RDY_getBusReq(reqValid),
		
		.putBusResp_resp(respData),
		.EN_putBusResp(respValid),
		.RDY_putBusResp(respReady),
		.getFinished(finished)
	);

	SimpleAxiMaster # ( 
		.C_M_AXI_ADDR_WIDTH(C_M_AXI_ADDR_WIDTH),
		.C_M_AXI_DATA_WIDTH(C_M_AXI_DATA_WIDTH)
	) iAXIM (
		.reqValid(reqValid),
		.reqReady(reqReady),
		.reqWr(reqWr),
		.reqAddr(reqAddr),
		.reqData(reqData),
		.respData(respData),
		.respValid(respValid),
		.respReady(respReady),
		.M_AXI_ACLK(M_AXI_ACLK),
		.M_AXI_ARESETN(M_AXI_ARESETN),
		.M_AXI_AWADDR(M_AXI_AWADDR),
		.M_AXI_AWPROT(M_AXI_AWPROT),
		.M_AXI_AWVALID(M_AXI_AWVALID),
		.M_AXI_AWREADY(M_AXI_AWREADY),
		.M_AXI_WDATA(M_AXI_WDATA),
		.M_AXI_WSTRB(M_AXI_WSTRB),
		.M_AXI_WVALID(M_AXI_WVALID),
		.M_AXI_WREADY(M_AXI_WREADY),
		.M_AXI_BRESP(M_AXI_BRESP),
		.M_AXI_BVALID(M_AXI_BVALID),
		.M_AXI_BREADY(M_AXI_BREADY),
		.M_AXI_ARADDR(M_AXI_ARADDR),
		.M_AXI_ARPROT(M_AXI_ARPROT),
		.M_AXI_ARVALID(M_AXI_ARVALID),
		.M_AXI_ARREADY(M_AXI_ARREADY),
		.M_AXI_RDATA(M_AXI_RDATA),
		.M_AXI_RRESP(M_AXI_RRESP),
		.M_AXI_RVALID(M_AXI_RVALID),
		.M_AXI_RREADY(M_AXI_RREADY)
	);
	

endmodule

module SimpleAxiMaster  #(
	// The master will start generating data from the C_M_START_DATA_VALUE value
		parameter  C_M_START_DATA_VALUE	= 32'hAA000000,
		// The master requires a target slave base address.
    // The master will initiate read and write transactions on the slave with base address specified here as a parameter.
		parameter  C_M_TARGET_SLAVE_BASE_ADDR	= 32'h40000000,
		// Width of M_AXI address bus. 
    // The master generates the read and write addresses of width specified as C_M_AXI_ADDR_WIDTH.
		parameter integer C_M_AXI_ADDR_WIDTH	= 32,
		// Width of M_AXI data bus. 
    // The master issues write data and accept read data where the width of the data bus is C_M_AXI_DATA_WIDTH
		parameter integer C_M_AXI_DATA_WIDTH	= 32
)(
		input wire reqValid,
		output wire reqReady,
		input wire reqWr,
		input wire [31:0]reqAddr,
		input wire [31:0]reqData,
		output wire [31:0]respData,
		output wire respValid,
		input wire respReady,
		// AXI clock signal
		input wire  M_AXI_ACLK,
		// AXI active low reset signal
		input wire  M_AXI_ARESETN,
		// Master Interface Write Address Channel ports. Write address (issued by master)
		output wire [C_M_AXI_ADDR_WIDTH-1 : 0] M_AXI_AWADDR,
		// Write channel Protection type.
    	// This signal indicates the privilege and security level of the transaction,
    	// and whether the transaction is a data access or an instruction access.
		output wire [2 : 0] M_AXI_AWPROT,
		// Write address valid. 
	    // This signal indicates that the master signaling valid write address and control information.
		output wire  M_AXI_AWVALID,
		// Write address ready. 
	    // This signal indicates that the slave is ready to accept an address and associated control signals.
		input wire  M_AXI_AWREADY,
		// Master Interface Write Data Channel ports. Write data (issued by master)
		output wire [C_M_AXI_DATA_WIDTH-1 : 0] M_AXI_WDATA,
		// Write strobes. 
    	// This signal indicates which byte lanes hold valid data.
    	// There is one write strobe bit for each eight bits of the write data bus.
		output wire [C_M_AXI_DATA_WIDTH/8-1 : 0] M_AXI_WSTRB,
		// Write valid. This signal indicates that valid write data and strobes are available.
		output wire  M_AXI_WVALID,
		// Write ready. This signal indicates that the slave can accept the write data.
		input wire  M_AXI_WREADY,
		// Master Interface Write Response Channel ports. 
    	// This signal indicates the status of the write transaction.
		input wire [1 : 0] M_AXI_BRESP,
		// Write response valid. 
    	// This signal indicates that the channel is signaling a valid write response
		input wire  M_AXI_BVALID,
		// Response ready. This signal indicates that the master can accept a write response.
		output wire  M_AXI_BREADY,
		// Master Interface Read Address Channel ports. Read address (issued by master)
		output wire [C_M_AXI_ADDR_WIDTH-1 : 0] M_AXI_ARADDR,
		// Protection type. 
    	// This signal indicates the privilege and security level of the transaction, 
    	// and whether the transaction is a data access or an instruction access.
		output wire [2 : 0] M_AXI_ARPROT,
		// Read address valid. 
    	// This signal indicates that the channel is signaling valid read address and control information.
		output wire  M_AXI_ARVALID,
		// Read address ready. 
    	// This signal indicates that the slave is ready to accept an address and associated control signals.
		input wire  M_AXI_ARREADY,
		// Master Interface Read Data Channel ports. Read data (issued by slave)
		input wire [C_M_AXI_DATA_WIDTH-1 : 0] M_AXI_RDATA,
		// Read response. This signal indicates the status of the read transfer.
		input wire [1 : 0] M_AXI_RRESP,
		// Read valid. This signal indicates that the channel is signaling the required read data.
		input wire  M_AXI_RVALID,
		// Read ready. This signal indicates that the master can accept the read data and response information.
		output wire  M_AXI_RREADY
    );

	wire clk = M_AXI_ACLK;


	localparam [1:0] READ_IDLE = 2'h0;
	localparam [1:0] READ_ADDR = 2'h1;
	localparam [1:0] READ_DATA = 2'h2;
	localparam [1:0] READ_RESP = 2'h3;

	reg	axi_arvalid_r;
	reg	axi_arvalid_rw;
	reg	[31:0] axi_araddr_r;
	reg	[31:0] axi_araddr_rw;
	reg	axi_rready_r;
	reg	axi_rready_rw;
	reg respValid_r;
	reg respValid_rw;
	reg [31:0] respData_r;
	reg [31:0] respData_rw;

	reg [1:0] read_state_r;
	reg [1:0] read_state_rw;

	always @(posedge clk) begin
		if (~M_AXI_ARESETN) begin
			axi_arvalid_r <= 1'b0;
			axi_araddr_r <= 0;
			axi_rready_r <= 1'b0;
			respValid_r <= 0;
			respData_r <= 0;
			read_state_r <= READ_IDLE;
		end else begin
			axi_arvalid_r <= axi_arvalid_rw;
			axi_araddr_r <= axi_araddr_rw;
			axi_rready_r <= axi_rready_rw;
			respValid_r <= respValid_rw;
			respData_r <= respData_rw;
			read_state_r <= read_state_rw;
		end
	end

	always @(*) begin
		read_state_rw = read_state_r;

		axi_arvalid_rw = 1'b0;
		axi_rready_rw = 1'b0;
		axi_araddr_rw = 32'h0;
		respData_rw = 32'h0;
		respValid_rw = 1'b0;

		case (read_state_r)
			READ_IDLE: begin
				if (reqValid && ~reqWr) begin
					read_state_rw = READ_ADDR;
					axi_arvalid_rw = 1'b1;
					axi_araddr_rw = {4'h0, reqAddr[27:0]};
				end
			end
			READ_ADDR: begin
				axi_araddr_rw = axi_araddr_r;
				axi_arvalid_rw = 1'b1;

				if (axi_arvalid_r && M_AXI_ARREADY) begin
					read_state_rw = READ_DATA;
				end
			end
			READ_DATA: begin
				axi_rready_rw = 1'b1;
				if (axi_rready_r && M_AXI_RVALID) begin
					respData_rw = M_AXI_RDATA;
					respValid_rw = 1'b1;
					read_state_rw = READ_RESP;
				end
			end
			READ_RESP: begin
				respData_rw = respData_r;
				respValid_rw = 1'b1;
				if (respValid_r && respReady) begin
					read_state_rw = READ_IDLE;
				end
			end
		endcase
	end

	localparam [1:0] WRITE_IDLE = 2'h0;
	localparam [1:0] WRITE_ADDR = 2'h1;
	localparam [1:0] WRITE_DATA = 2'h2;
	localparam [1:0] WRITE_RESP = 2'h3;

	reg	axi_awvalid_r;
	reg	axi_awvalid_rw;
	reg	[31:0] axi_awaddr_r;
	reg	[31:0] axi_awaddr_rw;
	reg	axi_wvalid_r;
	reg	axi_wvalid_rw;
	reg [31:0] reqData_r;
	reg [31:0] reqData_rw;

	reg [1:0] write_state_r;
	reg [1:0] write_state_rw;

	always @(posedge clk) begin
		if (~M_AXI_ARESETN) begin
			axi_awvalid_r <= 1'b0;
			axi_awaddr_r <= 0;
			axi_wvalid_r <= 1'b0;
			reqData_r <= 0;
			write_state_r <= WRITE_IDLE;
		end else begin
			axi_awvalid_r <= axi_awvalid_rw;
			axi_awaddr_r <= axi_awaddr_rw;
			axi_wvalid_r <= axi_wvalid_rw;
			reqData_r <= reqData_rw;
			write_state_r <= write_state_rw;
		end
	end

	always @(*) begin
		write_state_rw = write_state_r;

		axi_awvalid_rw = 1'b0;
		axi_awaddr_rw = 32'h0;
		axi_wvalid_rw = 1'b0;
		reqData_rw = reqData_r;

		case (write_state_r)
			WRITE_IDLE: begin
				if (reqValid && reqWr) begin
					write_state_rw = WRITE_ADDR;
					axi_awvalid_rw = 1'b1;
					axi_awaddr_rw = {4'h0, reqAddr[27:0]};
					reqData_rw = reqData;
				end
			end
			WRITE_ADDR: begin
				axi_awaddr_rw = axi_awaddr_r;
				axi_awvalid_rw = 1'b1;

				if (axi_awvalid_r && M_AXI_AWREADY) begin
					write_state_rw = WRITE_DATA;
				end
			end
			WRITE_DATA: begin
				axi_wvalid_rw = 1'b1;
				if (axi_wvalid_r && M_AXI_WREADY) begin
					write_state_rw = M_AXI_BVALID ? WRITE_IDLE : WRITE_RESP;
				end
			end
			WRITE_RESP: begin
				write_state_rw = M_AXI_BVALID ? WRITE_IDLE : WRITE_RESP;
			end
		endcase
	end

	assign M_AXI_ARVALID = axi_arvalid_r;
	assign M_AXI_ARADDR = axi_araddr_r;
	assign M_AXI_ARPROT = 0;

	assign M_AXI_RREADY = axi_rready_r;

	assign M_AXI_BREADY = 1'b1;


	assign M_AXI_AWVALID = axi_awvalid_r;
	assign M_AXI_AWADDR = axi_awaddr_r;
	assign M_AXI_AWPROT = 0;

	assign M_AXI_WVALID = axi_wvalid_r;
	assign M_AXI_WDATA = reqData_r;
	assign M_AXI_WSTRB = 4'hF;

	assign reqReady = reqWr ? (write_state_r == WRITE_IDLE) : (read_state_r == READ_IDLE);
	assign respValid = respValid_r;
	assign respData = respData_r;
endmodule
`default_nettype wire