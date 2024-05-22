import Core::*;
module mkSingleCoreTest(Empty);
    Core core <- mkCore(0, False);

    rule finishSim;
        if (core.getFinished()) $finish;
    endrule

    rule printBusReq;
        let x <- core.getBusReq();

        if (x.write_enable) $fdisplay(stderr, "Bus Request: store %d = %d", x.addr, x.data);
    endrule
endmodule
