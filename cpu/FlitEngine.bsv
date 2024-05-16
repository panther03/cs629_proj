import MemTypes::*;
import BRAM::*;
import FIFO::*;

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
    Reg#(Bit#(32)) addr <- mkReg(0);

    rule handleHeadFlit if (state == Idle)
        let flit = incoming.first(); incoming.deq();
        if (flit )
    endrule
endmodule