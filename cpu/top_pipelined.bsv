// PIPELINED SINGLE CORE PROCESSOR WITH 2 LEVEL CACHE
import RVUtil::*;
import BRAM::*;
import pipelined::*;
import FIFO::*;
import SpecialFIFOs::*;
import MemTypes::*;
import CacheInterface::*;
import Ehr::*;

interface Core;
    // Poll sync register
    method Bool getLocalSync();
    // Set all_sync register(s)
    method Action setAllSync(Bool startNotFinish);
    // Network giving the core a flit
    method Action putFlit(Flit f);
    // Core sending a flit out to the network
    method ActionValue#(Flit) getFlit();
endinterface

module mktop_pipelined(Core);
    // Instantiate the dual ported memory
    BRAM_Configure cfg = defaultValue();
    cfg.loadFormat = tagged Binary "zeroScratch.vmh";
    BRAM2Port#(Bit#(12), Word) scratch <- mkBRAM2Server(cfg); // 32K

    CacheInterface cache <- mkCacheInterface();
    RVIfc rv_core <- mkpipelined;
    FlitEngine fe <- mkFlitEngine();

    Reg#(Mem) ireq <- mkRegU;
    FIFO#(Mem) dreq <- mkPipelineFIFO;
    FIFO#(Mem) mmioreq <- mkFIFO;
    let debug = False;
    Reg#(Bit#(32)) cycle_count <- mkReg(0);
    Reg#(Bit#(32)) count_arrived <- mkReg(0);

    // Have I reached sync() command? (core sets this)
    Reg#(Bool) bsp_my_sync <- mkReg(False); 
    // Has everyone also reached sync() command? (core polls on this and resets)
    Ehr#(2, Bool) bsp_sync_all_start <- mkEhr(False);
    // Has everyone finished sync() and emptied out all network queues (core polls on this and resets)
    Ehr#(2, Bool) bsp_sync_all_end <- mkEhr(False); 

    rule tic;
	    cycle_count <= cycle_count + 1;
    endrule

    rule requestFE;
        let req <- fe.getScratchReq();
        scratch.portB.request.put(req);
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

            // set local sync register
            end else if (req.addr == 'hfd00_0000) begin
                bsp_my_sync <= unpack(req.data[0]);

            // clear all sync start register
            end else if (req.addr == 'hfd00_0004) begin
                // clearing takes priority
                bsp_sync_all_start[1] <= False;

            // clear all sync end register
            end else if (req.addr == 'hfd00_0008) begin
                // clearing takes priority
                bsp_sync_all_end[1] <= False;

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
            if (req.addr == 'hfd00_0000) begin
                mmioreq.enq(Mem { byte_en: req.byte_en, addr: 32'b0, data: {31'h0, pack(bsp_my_sync)}});
            // poll all sync start register
            end if (req.addr == 'hfd00_0004) begin
                mmioreq.enq(Mem { byte_en: req.byte_en, addr: 32'b0, data: {31'h0, pack(bsp_sync_all_start[0])}});
            // poll all sync end register
            end if (req.addr == 'hfd00_0008) begin
                mmioreq.enq(Mem { byte_en: req.byte_en, addr: 32'b0, data: {31'h0, pack(bsp_sync_all_end[0])}});
            end else if (req.addr[31:24] == 'hff) begin
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

    method Bool getLocalSync();
        return bsp_my_sync[0];
    endmethod

    method Action setAllSync(Bool startNotFinish);
        if (startNotFinish) begin
            bsp_sync_all_start[0] <= True;
        end else begin
            bsp_sync_all_end[0] <= True;
        end
    endmethod

    method Action putFlit(Flit f);
        // TODO: check the processor ID before we put it to the FE
        // for verificaton purposes (sanity check)
        fe.putFlit(f);
    endmethod

    method ActionValue#(Flit) getFlit();
        // TODO when we have the actual flit format
    endmethod
endmodule
