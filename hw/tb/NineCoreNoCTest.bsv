import Core::*;
import MeshNxN::*;

module mkNineCoreNoCTest();
    Core core0 <- mkCore(0, False);
    Core core1 <- mkCore(1, False);
    Core core2 <- mkCore(2, False);
    Core core3 <- mkCore(3, False);
    Core core4 <- mkCore(4, False);
    Core core5 <- mkCore(5, False);
    Core core6 <- mkCore(6, False);
    Core core7 <- mkCore(7, False);
    Core core8 <- mkCore(8, False);

    MeshNxN#(3) mesh3X3 <- mkMeshNxN;

    Reg#(Bool) c0sync_r <- mkReg(False);
    Reg#(Bool) c1sync_r <- mkReg(False);
    Reg#(Bool) c2sync_r <- mkReg(False);
    Reg#(Bool) c3sync_r <- mkReg(False);
    Reg#(Bool) c4sync_r <- mkReg(False);
    Reg#(Bool) c5sync_r <- mkReg(False);
    Reg#(Bool) c6sync_r <- mkReg(False);
    Reg#(Bool) c7sync_r <- mkReg(False);
    Reg#(Bool) c8sync_r <- mkReg(False);
    Reg#(SyncState) allsync_r <- mkReg(Unsync);

    rule regSyncs;
        c0sync_r <= core0.getLocalSync();
        c1sync_r <= core1.getLocalSync();
        c2sync_r <= core2.getLocalSync();
        c4sync_r <= core4.getLocalSync();
        c3sync_r <= core3.getLocalSync();
        c6sync_r <= core6.getLocalSync();
        c5sync_r <= core5.getLocalSync();
        c8sync_r <= core8.getLocalSync();
        c7sync_r <= core7.getLocalSync();
    endrule

    rule updateSync;
        
        if (
                c0sync_r &&
                c1sync_r &&
                c2sync_r &&
                c3sync_r &&
                c4sync_r &&
                c5sync_r &&
                c6sync_r &&
                c7sync_r &&
                c8sync_r
            ) begin
            allsync_r <= Start;
            
        end else if (
                        !c0sync_r && 
                        !c1sync_r &&
                        !c2sync_r && 
                        !c3sync_r && 
                        !c4sync_r && 
                        !c5sync_r && 
                        !c6sync_r && 
                        !c7sync_r && 
                        !c8sync_r
                    ) begin
            allsync_r <= Finish;
        end else begin
            allsync_r <= Unsync;
        end
    endrule

    rule propogateAllSync;
        core0.setAllSync(allsync_r);
        core1.setAllSync(allsync_r);
        core2.setAllSync(allsync_r);
        core3.setAllSync(allsync_r);
        core4.setAllSync(allsync_r);
        core5.setAllSync(allsync_r);
        core6.setAllSync(allsync_r);
        core7.setAllSync(allsync_r);
        core8.setAllSync(allsync_r);
    endrule
// NESWL
    rule core0Put;
        let f <- core0.getFlit();
        mesh3X3.dataLinks[0].putFlit(f);
    endrule

    rule core1Put;
        let f <- core1.getFlit();
        mesh3X3.dataLinks[1].putFlit(f);
    endrule

    rule core2Put;
        let f <- core2.getFlit();
        mesh3X3.dataLinks[2].putFlit(f);
    endrule

    rule core3Put;
        let f <- core3.getFlit();
        mesh3X3.dataLinks[3].putFlit(f);
    endrule

    rule core4Put;
        let f <- core4.getFlit();
        mesh3X3.dataLinks[4].putFlit(f);
    endrule

    rule core5Put;
        let f <- core5.getFlit();
        mesh3X3.dataLinks[5].putFlit(f);
    endrule

    rule core6Put;
        let f <- core6.getFlit();
        mesh3X3.dataLinks[6].putFlit(f);
    endrule

    rule core7Put;
        let f <- core7.getFlit();
        mesh3X3.dataLinks[7].putFlit(f);
    endrule

    rule core8Put;
        let f <- core8.getFlit();
        mesh3X3.dataLinks[8].putFlit(f);
    endrule

    rule core0Get;
        let f <- mesh3X3.dataLinks[0].getFlit();
        core0.putFlit(f);
    endrule

    rule core1Get;
        let f <- mesh3X3.dataLinks[1].getFlit();
        core1.putFlit(f);
    endrule

    rule core2Get;
        let f <- mesh3X3.dataLinks[2].getFlit();
        core2.putFlit(f);
    endrule

    rule core3Get;
        let f <- mesh3X3.dataLinks[3].getFlit();
        core3.putFlit(f);
    endrule

    rule core4Get;
        let f <- mesh3X3.dataLinks[4].getFlit();
        core4.putFlit(f);
    endrule

    rule core5Get;
        let f <- mesh3X3.dataLinks[5].getFlit();
        core5.putFlit(f);
    endrule

    rule core6Get;
        let f <- mesh3X3.dataLinks[6].getFlit();
        core6.putFlit(f);
    endrule

    rule core7Get;
        let f <- mesh3X3.dataLinks[7].getFlit();
        core7.putFlit(f);
    endrule

    rule core8Get;
        let f <- mesh3X3.dataLinks[8].getFlit();
        core8.putFlit(f);
    endrule

    rule endSimulation;
        if (
                core0.getFinished() && 
                core1.getFinished() && 
                core2.getFinished() && 
                core3.getFinished() && 
                core4.getFinished() && 
                core5.getFinished() && 
                core6.getFinished() && 
                core7.getFinished() && 
                core8.getFinished()
            ) begin
            $finish();
        end
    endrule
endmodule
