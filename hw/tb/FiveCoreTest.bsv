import Core::*;

module mkDualCoreTest();
    Core core0 <- mkCore(0, False);
    Core core1 <- mkCore(1, False);
    Core core2 <- mkCore(2, False);
    Core core3 <- mkCore(3, False);
    Core core4 <- mkCore(4, False);
    
    rule updateSync;
        let c0sync = core0.getLocalSync();
        let c1sync = core1.getLocalSync();
        let c2sync = core2.getLocalSync();
        let c3sync = core3.getLocalSync();
        let c4sync = core4.getLocalSync();

        if (c0sync && c1sync && c2sync && c3sync && c4sync) begin
            core0.setAllSync(True);
            core1.setAllSync(True);
            core2.setAllSync(True);
            core3.setAllSync(True);
            core4.setAllSync(True);
        end else if (!c0sync && !c1sync && !c2sync && !c3sync && !c4sync) begin
            core0.setAllSync(False);
            core1.setAllSync(False);
            core2.setAllSync(False);
            core3.setAllSync(False);
            core4.setAllSync(False);
        end
    endrule

    rule core0ToOthers;
        let f <- core0.getFlit();
        core1.putFlit(f);
        core2.putFlit(f);
        core3.putFlit(f);
        core4.putFlit(f);
    endrule
    
    rule xchgFlits1;
        let f1 <- core1.getFlit();
        core0.putFlit(f1);
    endrule	
    
    rule xchgFlits2;
        let f2 <- core2.getFlit();
        core0.putFlit(f2);
    endrule

    rule xchgFlits3;
        let f3 <- core3.getFlit();
        core0.putFlit(f3);
    endrule

    rule xchgFlits4;
        let f4 <- core4.getFlit();
        core0.putFlit(f4); 
    endrule

    rule endSimulation;
        if (core0.getFinished() && core1.getFinished()&& core2.getFinished()&& core3.getFinished()&& core4.getFinished()) begin
            $finish();
        end
    endrule
endmodule
