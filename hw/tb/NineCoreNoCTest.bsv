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

    rule updateSync;
        let c0sync = core0.getLocalSync();
        let c1sync = core1.getLocalSync();
        let c2sync = core2.getLocalSync();
        let c3sync = core3.getLocalSync();
        let c4sync = core4.getLocalSync();
        let c5sync = core5.getLocalSync();
        let c6sync = core6.getLocalSync();
        let c7sync = core7.getLocalSync();
        let c8sync = core8.getLocalSync();
        if (
                c0sync &&
                c1sync &&
                c2sync &&
                c3sync &&
                c4sync &&
                c5sync &&
                c6sync &&
                c7sync &&
                c8sync
            ) begin
            core0.setAllSync(Start);
            core1.setAllSync(Start);
            core2.setAllSync(Start);
            core3.setAllSync(Start);
            core4.setAllSync(Start);
            core5.setAllSync(Start);
            core6.setAllSync(Start);
            core7.setAllSync(Start);
            core8.setAllSync(Start);
        end else if (
                        !c0sync && 
                        !c1sync &&
                        !c2sync && 
                        !c3sync && 
                        !c4sync && 
                        !c5sync && 
                        !c6sync && 
                        !c7sync && 
                        !c8sync
                    ) begin
            core0.setAllSync(Finish);
            core1.setAllSync(Finish);
            core2.setAllSync(Finish);
            core3.setAllSync(Finish);
            core4.setAllSync(Finish);
            core5.setAllSync(Finish);
            core6.setAllSync(Finish);
            core7.setAllSync(Finish);
            core8.setAllSync(Finish);
        end else begin
            core0.setAllSync(Unsync);
            core1.setAllSync(Unsync);
            core2.setAllSync(Unsync);
            core3.setAllSync(Unsync);
            core4.setAllSync(Unsync);
            core5.setAllSync(Unsync);
            core6.setAllSync(Unsync);
            core7.setAllSync(Unsync);
            core8.setAllSync(Unsync);
        end
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
