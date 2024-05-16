// PIPELINED SINGLE CORE PROCESSOR WITH 2 LEVEL CACHE
import RVUtil::*;
import BRAM::*;
import pipelined::*;
import FIFO::*;
import SpecialFIFOs::*;
import MemTypes::*;
import CacheInterface::*;
// typedef Bit#(32) Word;

module mktop_pipelined(Empty);
    // Instantiate the dual ported memory
    BRAM_Configure cfg = defaultValue();
    cfg.loadFormat = tagged Binary "zeroScratch.vmh";
    BRAM2Port#(Bit#(12), Word) scratch <- mkBRAM2Server(cfg); // 32K


    CacheInterface cache <- mkCacheInterface();

    RVIfc rv_core <- mkpipelined;
    Reg#(Mem) ireq <- mkRegU;
    FIFO#(Mem) dreq <- mkPipelineFIFO;
    FIFO#(Mem) mmioreq <- mkFIFO;
    let debug = False;
    Reg#(Bit#(32)) cycle_count <- mkReg(0);
    Reg#(Bit#(32)) count_arrived <- mkReg(0);

    rule tic;
	    cycle_count <= cycle_count + 1;
    endrule

    rule requestI;
        let req <- rv_core.getIReq;
        if (debug) $display("Get IReq", fshow(req));
        ireq <= req;

        cache.sendReqInstr(CacheReq{word_byte: req.byte_en, addr: req.addr, data: req.data});

            // bram.portB.request.put(BRAMRequestBE{
            //         writeen: req.byte_en,
            //         responseOnWrite: True,
            //         address: truncate(req.addr >> 2),
            //         datain: req.data});
    endrule

    rule responseI;
        let x <- cache.getRespInstr();
        // let x <- bram.portB.response.get();
        let req = ireq;
        if (debug) $display("Get IResp ", fshow(req), fshow(x));
        req.data = x;
        rv_core.getIResp(req);
    endrule

    rule requestD;
        let req <- rv_core.getDReq;
        dreq.enq(req);
        if (debug) $display("Get DReq", fshow(req));
        // $display("DATA ",fshow(CacheReq{word_byte: req.byte_en, addr: req.addr, data: req.data}));
        cache.sendReqData(CacheReq{word_byte: req.byte_en, addr: req.addr, data: req.data});

        // bram.portA.request.put(BRAMRequestBE{
        //   writeen: req.byte_en,
        //   responseOnWrite: True,
        //   address: truncate(req.addr >> 2),
        //   datain: req.data});
    endrule

    rule responseD;
        // let x <- bram.portA.response.get();
        let x <- cache.getRespData();

        let req = dreq.first;
        dreq.deq();
        if (debug) $display("Get IResp ", fshow(req), fshow(x));
        req.data = x;
            rv_core.getDResp(req);
    endrule
  
    rule requestMMIO;
        let req <- rv_core.getMMIOReq;
        if (debug) $display("Get MMIOReq", fshow(req));

        // Write MMIO (ignore sub-word MMIO store)
        if (req.byte_en == 'hf) begin

            // putchar()
            if (req.addr ==  'hf000_fff0) begin
                // Writing to STDERR
                $fwrite(stderr, "%c", req.data[7:0]);
                $fflush(stderr);

            // exit()
            end else if (req.addr == 'hf000_fff8) begin
                $display("RAN CYCLES", cycle_count);

                // Exiting Simulation
                if (req.data == 0) begin
                    if (count_arrived == 0 ) $fdisplay(stderr, "  [0;32mPASS first thread [0m");
                    if (count_arrived == 1 ) $fdisplay(stderr, "  [0;32mPASS second thread [0m");
                end else begin
                    if (count_arrived == 0) $fdisplay(stderr, "  [0;31mFAIL first thread[0m (%0d)", req.data);
                    if (count_arrived == 1) $fdisplay(stderr, "  [0;31mFAIL second thread[0m (%0d)", req.data);
                end
                $fflush(stderr);
                count_arrived <= count_arrived + 1; 
                if (count_arrived == 1) $finish;

            // Write to scratchpad
            end else if (req.addr[31:24] == 'hff) begin
                if (debug) $display("[c=%d] write to %d, %d", cycle_count, req.addr[13:2], req.data);
                scratch.portA.request.put(BRAMRequest{
                    write: True,
                    responseOnWrite: False,
                    address: req.addr[13:2],
                    datain: req.data
                });
            end

            mmioreq.enq(req);
        // Read MMIO
        end else if (req.byte_en == 'h0) begin
            if (req.addr[31:24] == 'hff) begin
                if (debug) $display("[c=%d] read from %d", cycle_count, req.addr[13:2]);
                scratch.portA.request.put(BRAMRequest{
                    write: False,
                    responseOnWrite: False,
                    address: req.addr[13:2],
                    datain: ?
                });    
            end
        end else begin
            $fdisplay(stderr, "Illegal sub-word MMIO access");
            $finish;
        end
        
    endrule

    rule getScratchResp;
        let scratchResp <- scratch.portA.response.get();
        mmioreq.enq(Mem { byte_en: 4'b0, addr: 32'b0, data: scratchResp});
    endrule

    rule responseMMIO;
        let req = mmioreq.first();
        mmioreq.deq();
        if (debug) $display("Put MMIOResp", fshow(req));
        rv_core.getMMIOResp(req);
    endrule
    
endmodule
