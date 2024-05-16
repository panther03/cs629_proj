import Core::*;
module mkTopPipelined(Empty);
    Core core <- mkCore(0);

    rule finishSim;
        if (core.getFinished()) $finish;
    endrule
endmodule
