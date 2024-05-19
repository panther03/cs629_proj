import Core::*;

interface TopCore;
    // Bus Request
    method ActionValue#(CoreBusRequest) getBusReq();
    // Bus Response
    method Action putBusResp(Bit#(32) resp);
    // Has the core reached a halt
    method Bool getFinished();
endinterface

(* synthesize *)
module mkTopCore(TopCore);
    Core core <- mkCore(0);   

    method ActionValue#(CoreBusRequest) getBusReq();
        let x <- core.getBusReq();
        return x;
    endmethod

    method Action putBusResp(Bit#(32) resp);
        core.putBusResp(resp);
    endmethod

    method Bool getFinished();
        return core.getFinished();
    endmethod
endmodule

