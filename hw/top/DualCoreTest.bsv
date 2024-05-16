import Core::*;

module mkDualCoreTest();
    Core core0 <- mkCore(0);
    Core core1 <- mkCore(1);

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

    rule xchgFlits1;
        let f <- core0.getFlit();
        core1.putFlit(f);
    endrule

    rule xchgFlits2;
        let f <- core1.getFlit();
        core0.putFlit(f);
    endrule

    rule endSimulation;
        if (core0.getFinished() && core1.getFinished()) begin
            $finish();
        end
    endrule
endmodule
