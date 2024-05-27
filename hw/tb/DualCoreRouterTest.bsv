import Core::*;
import Router::*;

module mkDualCoreRouterTest();
    Core core0 <- mkCore(0, False);
    Core core1 <- mkCore(1, False);

    Router router <- mkRouter(0, 0);    // Coordinate of (0, 0)

    Reg#(Bool) started <- mkReg(False);

    rule init(!started);
        if(router.isInited) begin
          started <= True;
        end 
    endrule

    rule updateSync;
        let c0sync = core0.getLocalSync();
        let c1sync = core1.getLocalSync();
        if (c0sync && c1sync) begin
            core0.setAllSync(True);
            core1.setAllSync(True);
        end else if (!c0sync && !c1sync) begin
            core0.setAllSync(False);
            core1.setAllSync(False);
        end
    endrule
// NESWL
    rule core0Put;
        let f <- core0.getFlit();
        router.dataLinks[4].putFlit(f);
    endrule

    rule core1Put;
        let f <- core1.getFlit();
        router.dataLinks[1].putFlit(f);
    endrule

    rule core0Get;
        let f <- router.dataLinks[4].getFlit();
        core0.putFlit(f);
    endrule

    rule core1Get;
        let f <- router.dataLinks[1].getFlit();
        core1.putFlit(f);
    endrule

    rule endSimulation;
        if (core0.getFinished() && core1.getFinished()) begin
            $finish();
        end
    endrule
endmodule
