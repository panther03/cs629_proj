import Vector::*;
import FIFO::*;
import FIFOF::*;
import SpecialFIFOs::*;

import Ehr::*;
import NetworkTypes::*;
import MessageTypes::*;
import RoutingTypes::*;
import SwitchAllocTypes::*;

import CrossbarSwitch::*;
import MatrixArbiter::*;

(* synthesize *)
module mkOutPortArbiter(NtkArbiter#(NumPorts));
    // We provide an implementation of a priority arbiter,
    // it gives you the following method: 
    // method ActionValue#(Bit#(numRequesters)) getArbit(Bit#(numRequesters) reqBit);
    // you send a bitvector of all the client that would like to access a resource,
    // and it selects one clients among all of them (returned in one-hot
    // encoding) You can look at the implementation in MatrixArbiter if you are
    // curious, but you could also use a more naive implementation that does not
    // record previous requests
    
    Integer n = valueOf(NumPorts);
    NtkArbiter#(NumPorts)	matrixArbiter <- mkMatrixArbiter(n);
    return matrixArbiter;
endmodule

typedef Vector#(NumPorts, Direction)  ArbReq;
typedef Vector#(NumPorts, Direction)  ArbReqBits;
typedef Bit#(NumPorts)                ArbRes;

interface DataLink;
    method ActionValue#(Flit)         getFlit;
    method Action                     putFlit(Flit flit);
endinterface

interface Router;
    method Bool isInited;
    interface Vector#(NumPorts, DataLink)    dataLinks;
    method Bool getRouterSync();
endinterface

function Bool newHeadFlit (Vector#(NumPorts, FIFOF#(Flit)) inputBuffer, Integer inputPort);
    if (inputBuffer[inputPort].notEmpty && inputBuffer[inputPort].first.flitType == HEAD)
        return True;
    else return False;
endfunction

function Bool newTailFlit (Vector#(NumPorts, FIFOF#(Flit)) inputBuffer, Integer inputPort);
    if (inputBuffer[inputPort].notEmpty && inputBuffer[inputPort].first.flitType == TAIL)
        return True;
    else return False;
endfunction

function MeshHIdx getYCoordinate (FlitData headFlitData);
    Bit# (4) coreID = pack(headFlitData[21 : 18]);

    MeshHIdx yCoordinate = (unpack(coreID) / 3)[2:0];

    return yCoordinate;
endfunction

function MeshWIdx getXCoordinate (FlitData headFlitData);
    Bit# (4) coreID = pack(headFlitData[21 : 18]);

    MeshWIdx xCoordinate = (unpack(coreID) % 3)[2:0];
    
    return xCoordinate;
endfunction

function DirIdx computeDestinationPort (Flit headFlit, Bit#(3) routerX_, Bit#(3) routerY_); // Route Computation Logic is implemented here
    MeshHIdx destinationY = getYCoordinate( headFlit.flitData );
    MeshWIdx destinationX = getXCoordinate( headFlit.flitData );

    DirIdx dirIdx = dIdxNULL;

    if(currentRoutingAlgorithm == XY_) begin
        if (destinationX > (routerX_))
            dirIdx = dIdxEast;
        else if (destinationX < (routerX_)) 
            dirIdx = dIdxWest;
        else if (destinationY > (routerY_))
            dirIdx = dIdxSouth;
        else if (destinationY < (routerY_)) 
            dirIdx = dIdxNorth;
        else
            dirIdx = dIdxLocal;
    end else if (currentRoutingAlgorithm == YX_) begin
        if (destinationY > (routerY_))
            dirIdx = dIdxSouth;
        else if (destinationY < (routerY_)) 
            dirIdx = dIdxNorth;
        else if (destinationX > (routerX_))
            dirIdx = dIdxEast;
        else if (destinationX < (routerX_)) 
            dirIdx = dIdxWest;
        else
            dirIdx = dIdxLocal;
    end

    return dirIdx;
endfunction

// (* synthesize *)
module mkRouter #(Bit#(3) routerX, Bit#(3) routerY) (Router);

    /********************************* States *************************************/
    Reg#(Bool)                                inited         <- mkReg(False);
    // Note: these all need to be bypass FIFOs, otherwise there will be input flits 
    // "in flight" which do not see the allocated outputPortSource!
    // These would need to be stalled or the outputPortSource forwarded
    Vector#(NumPorts, FIFO#(ArbRes))          arbResBuf      <- replicateM(mkBypassFIFO);
    Vector#(NumPorts, FIFOF#(Flit))           inputBuffer    <- replicateM(mkSizedBypassFIFOF(4));
    Vector#(NumPorts, NtkArbiter#(NumPorts))  outPortArbiter <- replicateM(mkOutPortArbiter);
    CrossbarSwitch                            cbSwitch       <- mkCrossbarSwitch;
    Vector#(NumPorts, FIFOF#(Flit))           outputLatch   <- replicateM(mkSizedBypassFIFOF(1));
    Vector#(NumPorts, Reg#(ArbRes))           outputPortSource   <- replicateM(mkReg(0));     // Input source for each output port
    
    rule doInitialize(!inited);
        // Some initialization for the priority arbiters
        for(Integer outPort = 0; outPort < valueOf(NumPorts); outPort = outPort+1) begin
            outPortArbiter[outPort].initialize;
        end
        inited <= True;
    endrule 

    //for(Integer inPort = 0; inPort < valueOf(NumPorts); inPort = inPort + 1) begin
    //    rule routeComputation (inited && newHeadFlit(inputBuffer, inPort) && inputPortDestination[inPort] == dIdxNULL);
    //        DirIdx destinationPort = computeDestinationPort(inputBuffer[inPort].first, routerX, routerY);   // TODO: How to pass RouterX and RouterY to module?
    //        inputPortDestination[inPort] <= destinationPort;
    //    endrule
    //end
//
    //for(Integer inPort = 0; inPort < valueOf(NumPorts); inPort = inPort + 1) begin
    //    rule routeRelease (inited && newTailFlit(inputBuffer, inPort) && inputPortDestination[inPort] != dIdxNULL);
    //        inputPortDestination[inPort] <= dIdxNULL;
    //    endrule
    //end

    // ! rl_Switch_Arbitration needs to be scheduled before routeRelease since it has to read the inputPortDestination for tail flit which will
    // ! get reset by the routeRelease as soon as it sees a tail flit.

    for(Integer outPort=0; outPort<valueOf(NumPorts); outPort = outPort+1) begin
        rule rl_Switch_Arbitration(inited);

            // Has this out port already been allocated? (message not complete)
            if (outputPortSource[outPort] == 0) begin
                // If not, we will ask the arbiter which inport to take
                ArbRes request = 0; // Arbitration Request for the Output Port outPort

                for(Integer inPort = 0; inPort < valueOf(NumPorts); inPort = inPort + 1) begin
                    if (inputBuffer[inPort].notEmpty) begin
                        let flit = inputBuffer[inPort].first;
                        let destPort = computeDestinationPort(flit, routerX, routerY);
                        request[inPort] = (destPort == fromInteger(outPort) && (flit.flitType == HEAD)) ? 1 : 0;
                    end else begin
                        request[inPort] = 0;
                    end
                end

                let response <- outPortArbiter[outPort].getArbit(request);
                
                if (request != 0 && response != 0) begin
                    //$display("new [rx=%d][ry=%d] ops[i]=%d", routerX, routerY, outputPortSource[outPort]);
                    arbResBuf[outPort].enq(response);
                end
            end else begin
                //$display("reuse [rx=%d][ry=%d] ops[i]=%d", routerX, routerY, outputPortSource[outPort]);
                let inSource = outputPortSource[outPort];
                if (inputBuffer[dir2Idx(inSource)].notEmpty)
                    arbResBuf[outPort].enq(inSource);
            end            

//            for (Integer i = 0; i < valueOf(NumPorts); i = i + 1) begin
  //          end
        endrule
    end

    for(Integer outPort=0; outPort<valueOf(NumPorts); outPort = outPort+1) begin
        rule rl_Switch_Traversal(inited);
            /*
            deq arbResBuf
            Read the input winners, and push them to the crossbar
            */ 

            let winner = arbResBuf[outPort].first; arbResBuf[outPort].deq();
            Bit#(3) winnerIdx = arbitRes2DirIdx(winner); 

            // if(winnerIdx != 3'b111) begin
                let winnerInputFlit = inputBuffer[winnerIdx].first; inputBuffer[winnerIdx].deq();
                cbSwitch.crossbarPorts[winnerIdx].putFlit(winnerInputFlit, fromInteger(outPort));
            // end
            outputPortSource[outPort] <= (winnerInputFlit.flitType == TAIL) ? 0 : winner;
            //$display("[rx=%d][ry=%d][Switch Traversal][Output Port %0d] Winner Input: %0d\tFlit: ", routerX, routerY, outPort, winnerIdx, fshow(winnerInputFlit));
        endrule
    end
    
    for(Integer outPort=0; outPort<valueOf(NumPorts); outPort = outPort+1)
    begin
        rule rl_enqOutLatch(inited);
            // Use several rules to dequeue from the cross bar output and push into the output ports queues 
            let outputFlit <- cbSwitch.crossbarPorts[outPort].getFlit;
            outputLatch[outPort].enq(outputFlit);

            //$display("[rx=%d][ry=%d][Enqueue Latch][Output Port %0d] Flit: ", routerX, routerY, outPort, fshow(outputFlit));
        endrule
    end

    /***************************** Router Interface ******************************/

    Vector#(NumPorts, DataLink) dataLinksDummy;
    for(DirIdx prt = 0; prt < fromInteger(valueOf(NumPorts)); prt = prt+1)
    begin
        dataLinksDummy[prt] =

        interface DataLink
            method ActionValue#(Flit) getFlit if(outputLatch[prt].notEmpty);
                Flit retFlit = outputLatch[prt].first();
                outputLatch[prt].deq();
                return retFlit;
            endmethod

            method Action putFlit(Flit flit) if(inputBuffer[prt].notFull);
                inputBuffer[prt].enq(flit);
            endmethod
        endinterface;
    end 

    interface dataLinks = dataLinksDummy;

    method Bool isInited;
        return inited; 
    endmethod
    
    method Bool getRouterSync();
    	Bool ret = True;
    	
    	for(Integer routerPort = 0; routerPort < valueOf(NumPorts); routerPort = routerPort + 1) begin
    		ret = ret && (!inputBuffer[routerPort].notEmpty) && (!outputLatch[routerPort].notEmpty);
    	end
    	
    	return ret;
    endmethod

endmodule
