import Core::*;
import FlitEngine::*;
import MessageTypes::*;
import NetworkTypes::*;
import Assert::*;

module mkFiveCoreTest();
    Core core0 <- mkCore(0, False);
    Core core1 <- mkCore(1, False);
    Core core2 <- mkCore(2, False);
    Core core3 <- mkCore(3, False);
    Core core4 <- mkCore(4, False);

    Reg#(EngineState) state <- mkReg(Idle);
    Reg#(Bit#(2)) cpuId <- mkReg(0);
    Reg#(Maybe#(Bit#(2))) route_cpuId <- mkReg(tagged Invalid);
    
    rule updateSync;
        let c0sync = core0.getLocalSync();
        let c1sync = core1.getLocalSync();
        let c2sync = core2.getLocalSync();
        let c3sync = core3.getLocalSync();
        let c4sync = core4.getLocalSync();

        if (c0sync && c1sync && c2sync && c3sync && c4sync) begin
            core0.setAllSync(Start);
            core1.setAllSync(Start);
            core2.setAllSync(Start);
            core3.setAllSync(Start);
            core4.setAllSync(Start);
        end else if (!c0sync && !c1sync && !c2sync && !c3sync && !c4sync) begin
            core0.setAllSync(Finish);
            core1.setAllSync(Finish);
            core2.setAllSync(Finish);
            core3.setAllSync(Finish);
            core4.setAllSync(Finish);
        end else begin 
            core0.setAllSync(Unsync);
            core1.setAllSync(Unsync);
            core2.setAllSync(Unsync);
            core3.setAllSync(Unsync);
            core4.setAllSync(Unsync);
        end
    endrule

    rule core0ToOthersHead if (state == Idle);
        let f <- core0.getFlit();
        //$display("(head) putting a flit: ", fshow(f));
        dynamicAssert(f.flitType == HEAD, "first packet was not head packet");
        let flitCpuId = pack(f.flitData)[21:18];
        state <= Handling;
        let cpuId_next = (flitCpuId - 1)[1:0];
        cpuId <= cpuId_next;
        case (cpuId_next) 
            2'h0: core1.putFlit(f);
            2'h1: core2.putFlit(f);
            2'h2: core3.putFlit(f);
            2'h3: core4.putFlit(f);
        endcase
    endrule


    rule core0ToOthersHandle if (state == Handling);
        let f <- core0.getFlit();
        //$display("(body) putting a flit: ", fshow(f));
        if (f.flitType == TAIL) begin
            state <= Idle;
        end
        case (cpuId) 
            2'h0: core1.putFlit(f);
            2'h1: core2.putFlit(f);
            2'h2: core3.putFlit(f);
            2'h3: core4.putFlit(f);
        endcase
    endrule
    
    rule xchgFlits1 if (fromMaybe(2'b00, route_cpuId) == 2'b00);
        let f1 <- core1.getFlit();
        route_cpuId <= (f1.flitType == TAIL) ? tagged Invalid : tagged Valid(2'b00);

        core0.putFlit(f1);
    endrule	
    
    rule xchgFlits2 if (fromMaybe(2'b01, route_cpuId) == 2'b01);
        let f2 <- core2.getFlit();
        route_cpuId <= (f2.flitType == TAIL) ? tagged Invalid : tagged Valid(2'b01);

        core0.putFlit(f2);
    endrule

    rule xchgFlits3 if (fromMaybe(2'b10, route_cpuId) == 2'b10);
        let f3 <- core3.getFlit();
        route_cpuId <= (f3.flitType == TAIL) ? tagged Invalid : tagged Valid(2'b10);

        core0.putFlit(f3);
    endrule

    rule xchgFlits4 if (fromMaybe(2'b11, route_cpuId) == 2'b11);
        let f4 <- core4.getFlit();
        route_cpuId <= (f4.flitType == TAIL) ? tagged Invalid : tagged Valid(2'b11);

        core0.putFlit(f4); 
    endrule

    rule endSimulation;
        if (core0.getFinished() && core1.getFinished()&& core2.getFinished()&& core3.getFinished()&& core4.getFinished()) begin
            $finish();
        end
    endrule
endmodule
