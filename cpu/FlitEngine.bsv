import MemTypes::*;
import BRAM::*;
import FIFO::*;

import MessageTypes::*;

interface FlitEngine;
    // Handle incoming flit
    method Action putFlit(Flit f);
    // Read queued request to scratchpad
    method ActionValue#(BRAMRequest) getScratchReq();
endinterface

typedef enum{Idle, Handling} EngineState deriving (Eq, Bits, FShow);

module mkFlitEngine(FlitEngine);
    Reg#(EngineState) state <- mkReg(Idle);
    FIFO#(Flit) incoming <- mkFIFO();
    FIFO#(BRAMRequest) outgoing <- mkFIFO();
    Reg#(Bit#(12)) addr <- mkReg(0);
    Reg#(Bit#(4)) burstCtr <- mkReg(0);
    Reg#(Bit#(4)) burstCtrF <- mkReg(0);

    rule propogateBurstCtr;
        burstCtrF <= burstCtr;
    endrule

    rule handleHeadFlit if (state == Idle)
        let flit = incoming.first(); incoming.deq();
        if (flit.flitType != flitType.HEAD) begin
            $fdisplay(stderr, "Something has gone horribly wrong. Engine received non-head packet in IDLE state");
        end
        Bit#(32) data = pack(flit.flitData);
        // Bottom 12 bits, shifted left by 2 for simplicity contain address
        addr <= data[13:2];
        // next 4 bits contains the burst count, up to 15 (= 16 bursts)
        burstCtr <= data[17:14];
        state <= Handling;
    endrule

    rule handleBodyFlit if (state == Handling) 
        if (flit.flitType == flitType.BODY) begin
            outgoing.enq(BRAMRequest {
                write: True,
                responseOnWrite: False,
                address: addr,
                datain: flit.flitData
            });
            burstCtr <= burstCtr - 1;
            addr <= addr + 1;
        end else if (flit.flitType == flitType.TAIL) begin 
            if (burstCtrF != 0) begin
                $fdisplay(stderr, "Burst counter did not go to 0 before seeing tail. Missing %d packets", burstCtrF);
            end
            state <= Idle;
        end else begin
            $fdisplay(stderr, "Why am I receiving another head packet before a tail?")
        end
    endrule

    method Action putFlit(Flit f);
        incoming.enq(f);
    endmethod

    method ActionValue#(BRAMRequest) getScratchReq();
        let req = outgoing.first; outgoing.deq();
        return req
    endmethod
endmodule