import Vector::*;
import Ehr::*;

import NetworkTypes::*;
import MessageTypes::*;
import SwitchAllocTypes::*;
import RoutingTypes::*;


interface CrossbarPort;
  method Action putFlit(Flit traverseFlit, DirIdx destDirn);
  method ActionValue#(Flit) getFlit; 
endinterface

interface CrossbarSwitch;
  interface Vector#(NumPorts, CrossbarPort) crossbarPorts;
endinterface

// This fucntion returns a non -1 value if any of the input ports are willing to send data to the output port "ports"
function Integer isOutputReady (Vector#(NumPorts, Vector#(NumPorts, Reg#(Maybe#(SwitchFlit)))) mrmwRegisters, Integer ports, Vector#(NumPorts, Reg#(Bit#(3))) clearingIndex);
  
  Integer selection = -1;

  for(Integer i = 0; i < valueOf(NumPorts); i = i + 1) begin
    if (  isValid(mrmwRegisters[i][ports]) && 
          fromMaybe(
            SwitchFlit { 
              flit: Flit {flitType: INVALID, flitData: ?}, 
              destDirn: dIdxNULL
            }, 
            mrmwRegisters[i][ports]
          ).destDirn == fromInteger(ports) &&
          clearingIndex[ports] == 3'b111
        ) begin
      selection = i;
    end
  end

  return selection;

endfunction

// This function returns True if this input port can take a new input. THis would be true if any of the registers
// of this input are tagged Invalid. This would mean that the the output port has already taken away the data 
// from the input port which is why the input-output register has been tagged Invalid
function Bool isInputEmpty (Vector#(NumPorts, Vector#(NumPorts, Reg#(Maybe#(SwitchFlit)))) mrmwRegisters, Integer ports);
  Bool full = True;

  for(Integer i = 0; i < valueOf(NumPorts); i = i + 1) begin
    full = full && isValid(mrmwRegisters[ports][i]);
  end

  return !full;
endfunction

(* synthesize *)
module mkCrossbarSwitch(CrossbarSwitch);
  /*
    implement the crossbar

    To define a vector of methods (with NumPorts*2 methods) you can use the following syntax:

    Vector#(NumPorts, CrossbarPort) crossbarPortsConstruct;
    for (Integer ports=0; ports < valueOf(NumPorts); ports = ports+1) begin
      crossbarPortsConstruct[ports] =
        interface CrossbarPort
          method Action putFlit(Flit traverseFlit, DirIdx destDirn);
            //  body for your method putFlit[ports]
          endmethod
          method ActionValue#(Flit) getFlit;
            //  body for your method getFlit[ports]
          endmethod
        endinterface;
    end
    interface crossbarPorts = crossbarPortsConstruct;

  */

  Vector#(NumPorts, Vector#(NumPorts, Reg#(Maybe#(SwitchFlit)))) mrmwRegisters <- replicateM (replicateM(mkReg(tagged Invalid)));
  Vector#(NumPorts, Reg#(Bit#(3))) clearingIndex <- replicateM(mkReg(3'b111));
  // First dimension will be written by Input ports and the Second dimension will be read by the Output ports

  // for (Integer ports=0; ports < valueOf(NumPorts); ports = ports+1) begin
  //   rule outputPortStatus if(isOutputReady(mrmwRegisters, ports, clearingIndex) != -1);
  //         $display ("[Port %0d] Something here", ports);
  //   endrule
  // end

  for (Integer ports=0; ports < valueOf(NumPorts); ports = ports+1) begin
    rule clearingIndexRule if(clearingIndex[ports] != 3'b111);
      mrmwRegisters[clearingIndex[ports]][ports] <= tagged Invalid;
      clearingIndex[ports] <= 3'b111;
    endrule
  end

  Vector#(NumPorts, CrossbarPort) crossbarPortsConstruct;
    for (Integer ports=0; ports < valueOf(NumPorts); ports = ports+1) begin
      crossbarPortsConstruct[ports] =
        interface CrossbarPort
          method Action putFlit(Flit traverseFlit, DirIdx destDirn) if (isInputEmpty(mrmwRegisters, ports));
            //$display ("[Port %0d][putFlit] Dest Dirn: %0d\t", ports, destDirn, fshow(traverseFlit) );
            //  body for your method putFlit[ports]
            for(Integer i = 0; i < valueOf(NumPorts); i = i + 1) begin
              mrmwRegisters[ports][i] <= tagged Valid SwitchFlit{flit: traverseFlit, destDirn: destDirn};
            end
          endmethod

          method ActionValue#(Flit) getFlit if(isOutputReady(mrmwRegisters, ports, clearingIndex) != -1);
            //  body for your method getFlit[ports]

            Flit outputFlit = ?;

            Integer selection = isOutputReady(mrmwRegisters, ports, clearingIndex);

            for(Integer i = 0; i < valueOf(NumPorts); i = i + 1) begin
              if (isValid(mrmwRegisters[i][ports]) && fromMaybe(SwitchFlit {flit: Flit {flitType: INVALID, flitData: ?}, destDirn: dIdxNULL}, mrmwRegisters[i][ports]).destDirn == fromInteger(ports)) begin
                selection = i;
              end
            end

            if(selection != -1) begin
              outputFlit = fromMaybe(SwitchFlit {flit: Flit {flitType: INVALID, flitData: ?}, destDirn: dIdxNULL}, mrmwRegisters[selection][ports]).flit;
              // mrmwRegisters[selection][ports] <= tagged Invalid;
              clearingIndex[ports] <= fromInteger(selection);
            end

            //$display ("[Port %0d][getFlit] ", ports, fshow(outputFlit));

            return outputFlit;

          endmethod
        endinterface;
    end
  interface crossbarPorts = crossbarPortsConstruct;

endmodule
