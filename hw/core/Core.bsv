// PIPELINED SINGLE CORE PROCESSOR WITH 2 LEVEL CACHE
// system imports
import BRAM::*;
import FIFO::*;
import FIFOF::*;
import SpecialFIFOs::*;
import Ehr::*;
// local imports
import RVUtil::*;
import PipelinedSyn::*;

import MemTypes::*;
import NetworkTypes::*;
import CacheInterface::*;

import FlitEngine::*;
import MessageTypes::*;

typedef enum{Unsync, Start, Finish} SyncState deriving (Eq, Bits, FShow);

typedef struct {
    // TODO: the address doesn't need to be this big for our purposes
    Bit#(32) addr;
    Bit#(32) data;
    Bool write_enable;
} CoreBusRequest deriving (Bits);

interface Core;
    // Poll sync register
    method Bool getLocalSync();
    // Set all_sync register(s)
    method Action setAllSync(SyncState newState);
    // Core sending a flit out to the network
    method ActionValue#(Flit) getFlit();
    // Network giving the core a flit
    method Action putFlit(Flit f);
    // Bus Request
    method ActionValue#(CoreBusRequest) getBusReq();
    // Bus Response
    method Action putBusResp(Bit#(32) resp);
    // Has the core reached a halt
    method Bool getFinished();
endinterface

module mkCore #(Bit#(4) coreId, Bool multithreaded) (Core);
`ifdef CACHE_ENABLE
    CacheInterface cache <- mkCacheInterface();
    BRAM_Configure cfg = defaultValue();
    cfg.loadFormat = tagged Binary "zeroScratch.mem";
    BRAM2Port#(Bit#(12), Word) scratch <- mkBRAM2Server(cfg); // 32K
`else
    // Instantiate the dual ported memory
    BRAM_Configure cfg = defaultValue();
    cfg.loadFormat = tagged Hex "mem.mem";
    BRAM2PortBE#(Bit#(12), Word, 4) bram <- mkBRAM2ServerBE(cfg);
`endif

    RVIfc rv_core <- mkPipelined(multithreaded);
    FlitEngine fe <- mkFlitEngine();

    FIFO#(CoreBusRequest) busReqs <- mkFIFO;
    FIFO#(Bit#(32)) busResps <- mkFIFO;

    FIFOF#(Flit) outgoingFlits <- mkFIFOF;
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

    rule requestI;
        let req <- rv_core.getIReq;
        if (debug) $display("Get IReq", fshow(req));
        ireq <= req;

`ifdef CACHE_ENABLE
        cache.sendReqInstr(CacheReq{word_byte: req.byte_en, addr: req.addr, data: req.data});
`else
        bram.portB.request.put(BRAMRequestBE{
                    writeen: req.byte_en,
                    responseOnWrite: True,
                    address: truncate(req.addr >> 2),
                    datain: req.data});
`endif
    endrule

    rule responseI;
`ifdef CACHE_ENABLE
        let x <- cache.getRespInstr();
`else
        let x <- bram.portB.response.get();
`endif
        let req = ireq;
        if (debug) $display("Get IResp ", fshow(req), fshow(x));
        req.data = x;
        rv_core.getIResp(req);
    endrule

`ifndef CACHE_ENABLE
(* descending_urgency = "requestFE, requestD" *)
`endif
    rule requestD;
        let req <- rv_core.getDReq;
        dreq.enq(req);
        if (debug) $display("Get DReq", fshow(req));

`ifdef CACHE_ENABLE
        cache.sendReqData(CacheReq{word_byte: req.byte_en, addr: req.addr, data: req.data});
`else
        bram.portA.request.put(BRAMRequestBE{
          writeen: req.byte_en,
          responseOnWrite: True,
          address: truncate(req.addr >> 2),
          datain: req.data});
`endif
    endrule

    rule responseD;
`ifdef CACHE_ENABLE
        let x <- cache.getRespData();
`else 
        let x <- bram.portA.response.get();
`endif
        let req = dreq.first;
        dreq.deq();
        if (debug) $display("Get IResp ", fshow(req), fshow(x));
        req.data = x;
            rv_core.getDResp(req);
    endrule

    // for shared scratch memory, let bluespec schedule behind dmem; this is fine
    rule requestFE;
        let req <- fe.getScratchReq();
`ifdef CACHE_ENABLE
        scratch.portB.request.put(BRAMRequest {
            write: True,
            responseOnWrite: False,
            address: req.addr,
            datain: req.data
        });
`else
        bram.portA.request.put(BRAMRequestBE{
          writeen: 4'hF,
          responseOnWrite: False,
          address: req.addr,
          datain: req.data
        });
`endif
    endrule
  
  (* descending_urgency = "getBusResp, requestMMIO" *)
    rule requestMMIO;
        let req <- rv_core.getMMIOReq;
        if (debug) $display("Get MMIOReq", fshow(req));

        // Write MMIO (ignore sub-word MMIO store)
        else if (req.byte_en == 'hf) begin
            // Send out to bus
            if (req.addr[31:28] == 'he) begin
                busReqs.enq(CoreBusRequest{
                    addr: req.addr,
                    data: req.data,
                    write_enable: True
                });
            // putchar()
            end else if (req.addr ==  'hf000_fff0) begin
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

            end else if (req.addr[31:4] == 'hfe00_000) begin
                FlitType ft = case (req.addr[3:0]) 
                    4'h0: HEAD;
                    4'h4: BODY;
                    4'h8: TAIL;
                    default: INVALID;
                endcase;
                let f = Flit { flitType: ft, flitData: req.data};
                if (debug) $display("Sending out flit: ", fshow(f));
                outgoingFlits.enq(f);
            end
`ifdef CACHE_ENABLE
            // Write to scratchpad
            else if (req.addr[31:24] == 'hff) begin
                if (debug) $display("[c=%d] write to %d, %d", cycle_count, req.addr[13:2], req.data);
                scratch.portA.request.put(BRAMRequest{
                    write: True,
                    responseOnWrite: False,
                    address: req.addr[13:2],
                    datain: req.data
                });
            end
`endif
            mmioreq.enq(req);
        // Read MMIO
        end else if (req.byte_en == 'h0) begin
            if (req.addr[31:28] == 'he) begin
                busReqs.enq(CoreBusRequest{
                    addr: req.addr,
                    data: ?,
                    write_enable: False
                });
            end else if (req.addr == 'hfd00_0000) begin
                mmioreq.enq(Mem { byte_en: req.byte_en, addr: req.addr, data: {31'h0, pack(bsp_my_sync)}});
            // poll all sync start register
            end if (req.addr == 'hfd00_0004) begin
                mmioreq.enq(Mem { byte_en: req.byte_en, addr: req.addr, data: {31'h0, pack(bsp_sync_all_start[1])}});
            // poll all sync end register
            end if (req.addr == 'hfd00_0008) begin
                mmioreq.enq(Mem { byte_en: req.byte_en, addr: req.addr, data: {31'h0, pack(bsp_sync_all_end[1])}});
            end if (req.addr == 'hfd00_000C) begin
                mmioreq.enq(Mem { byte_en: req.byte_en, addr: req.addr, data: {28'h0, coreId}});
            end 
`ifdef CACHE_ENABLE 
                else if (req.addr[31:24] == 'hff) begin
                if (debug) $display("[c=%d] read from %d", cycle_count, req.addr[13:2]);
                scratch.portA.request.put(BRAMRequest{
                    write: False,
                    responseOnWrite: False,
                    address: req.addr[13:2],
                    datain: ?
                });    
            end
`endif
        end else begin
            $fdisplay(stderr, "Illegal sub-word MMIO access");
            $finish;
        end
    endrule

// this rule doesnt need to exist w/o cache
`ifdef CACHE_ENABLE
    rule getScratchResp;
        let scratchResp <- scratch.portA.response.get();
        mmioreq.enq(Mem { byte_en: 4'b0, addr: 32'b0, data: scratchResp});
    endrule
`endif

    rule getBusResp;
        let busResp = busResps.first(); busResps.deq();
        mmioreq.enq(Mem { byte_en: 4'b0, addr: 32'b0, data: busResp});
    endrule

    rule responseMMIO;
        let req = mmioreq.first();
        mmioreq.deq();
        if (debug) $display("Put MMIOResp", fshow(req));
        rv_core.getMMIOResp(req);
    endrule

    method Bool getLocalSync();
        // Why the OR? we are abusing this method a bit.
        // If the system is ANDing our signal and making sure we are sync'd, then we have sync=1 so the expression is 1.
        // If we are 0, then the system could be waiting on all syncs to be low. In that case,
        // we also want to make sure there are no flits in flight. Thus, we OR with the not empty signal: this will prevent prematurely moving on from sync().

        // NOTE: this also assumes that there will be no outgoing flits before sync()!
        // If that happens, we will be marked as sync'd, which will be disastrous!
        return bsp_my_sync || outgoingFlits.notEmpty;
    endmethod

    method Action setAllSync(SyncState newState);
        case (newState)
            Unsync: begin
                bsp_sync_all_start[0] <= False;
                bsp_sync_all_end[0] <= False;
            end
            Start: begin
                bsp_sync_all_start[0] <= True;
                bsp_sync_all_end[0] <= False;
            end
            Finish: begin
                bsp_sync_all_start[0] <= False;
                bsp_sync_all_end[0] <= True;
            end
        endcase
    endmethod

    method Action putFlit(Flit f);
        // TODO: check the processor ID before we put it to the FE
        // for verificaton purposes (sanity check)
        let flitCpuId = pack(f.flitData)[21:18];
        if (f.flitType == HEAD && flitCpuId != coreId) begin
            $fdisplay(stderr, "(c=%d) received a flit for %d, not me: ", coreId, flitCpuId, fshow(f));
        end else begin
            $fdisplay(stderr, "(c=%d) new flit: ", coreId, fshow(f));
            fe.putFlit(f);
        end
    endmethod

    method ActionValue#(Flit) getFlit();
        let f = outgoingFlits.first(); outgoingFlits.deq();
        return f;
    endmethod

    method Bool getFinished();
        return (multithreaded ? (count_arrived > 1) : (count_arrived == 1));
    endmethod

    method ActionValue#(CoreBusRequest) getBusReq();
        let f = busReqs.first(); busReqs.deq();
        return f;
    endmethod

    method Action putBusResp(Bit#(32) resp);
        busResps.enq(resp);
    endmethod
endmodule
