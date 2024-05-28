import NetworkTypes::*;
import Vector::*;
import Router::*;
import FIFOF::*;
import SpecialFIFOs::*;
import MessageTypes::*;
import RoutingTypes::*;

/*
  Just for Area/Power estimation of a single router
*/
typedef 200000 TestCount;

module mkRouterTestBench();
  Router router <- mkRouter(0, 0);
  Reg#(Bool) started <- mkReg(False);
  Reg#(Bit#(32)) sent <- mkReg(0);
  Reg#(Bool) passed <- mkReg(True);
  Reg#(Data) clkCount <- mkReg(0);
  Vector#(NumPorts, Reg#(Data))    receive_counter <- replicateM(mkReg(0));
  Reg#(Data) flitCount <- mkReg(0);
  Vector#(NumPorts, FIFOF#(Flit))  verify_queue <- replicateM(mkBypassFIFOF);

  rule init(!started);
    if(router.isInited) begin
      started <= True;
    end 
  endrule

  rule doCount(started);
    clkCount <= clkCount +1;
  endrule

  rule rl_insertFlits(clkCount < fromInteger(valueOf(TestCount)));

    Flit headFlit = ?; Flit bodyFlit1 = ?; Flit bodyFlit2 = ?; Flit bodyFlit3 = ?; Flit bodyFlit4 = ?; Flit tailFlit = ?;
      
    headFlit.flitType = HEAD;
    headFlit.flitData = (1 << 18);   // Destination Cooridnate (1, 1). For XY, output should be on East Port 
    bodyFlit1.flitType = BODY;
    bodyFlit1.flitData = 1;
    bodyFlit2.flitType = BODY;
    bodyFlit2.flitData = 2;
    bodyFlit3.flitType = BODY;
    bodyFlit3.flitData = 3;
    bodyFlit4.flitType = BODY;
    bodyFlit4.flitData = 4;
    tailFlit.flitType = TAIL;
    tailFlit.flitData = (1 << 18);

    if(sent == 0) begin
      verify_queue[1].enq(headFlit); // Local to East

      router.dataLinks[4].putFlit(headFlit);  // Local to East
      $display("[0;33mInsertFlits[0m\t data=%0d into Local-input port0: target East-output port0", headFlit.flitData);
      sent <= sent + 1;
    end else if (sent == 1) begin
      verify_queue[1].enq(bodyFlit1);

      router.dataLinks[4].putFlit(bodyFlit1);
      $display("[0;33mInsertFlits[0m\t data=%0d into Local-input port0: target East-output port0", bodyFlit1.flitData);
      sent <= sent + 1;
    end else if (sent == 2) begin
      verify_queue[1].enq(bodyFlit2);

      router.dataLinks[4].putFlit(bodyFlit2);
      $display("[0;33mInsertFlits[0m\t data=%0d into Local-input port0: target East-output port0", bodyFlit2.flitData);
      sent <= sent + 1;
    end else if (sent == 3) begin
      verify_queue[1].enq(bodyFlit3);

      router.dataLinks[4].putFlit(bodyFlit3);
      $display("[0;33mInsertFlits[0m\t data=%0d into Local-input port0: target East-output port0", bodyFlit3.flitData);
      sent <= sent + 1;
    end else if (sent == 4) begin
      verify_queue[1].enq(bodyFlit4);

      router.dataLinks[4].putFlit(bodyFlit4);
      $display("[0;33mInsertFlits[0m\t data=%0d into Local-input port0: target East-output port0", bodyFlit4.flitData);
      sent <= sent + 1;
    end else if (sent == 5) begin
      verify_queue[1].enq(tailFlit);
      
      router.dataLinks[4].putFlit(tailFlit);
      $display("[0;33mInsertFlits[0m\t data=%0d into Local-input port0: target East-output port0", tailFlit.flitData);
      sent <= sent + 1;
    end
  endrule

  for(Integer i=0;i<valueOf(NumPorts); i=i+1) begin
    rule getFlits_port if(started); // && verify_queue[0].notEmpty);
      let temp_receive_flit <- router.dataLinks[i].getFlit();
      Flit verify_flit_vec = verify_queue[i].first();
      verify_queue[i].deq();
      if (temp_receive_flit.flitData != verify_flit_vec.flitData)  begin
        $fdisplay(stderr, "[0;31mFAIL[0m (port%0d receives %0d, expected %0d)", i, temp_receive_flit.flitData, verify_flit_vec.flitData);
        $finish;
      end
      $display("[0;34mGetFlits[0m \t from port: data=%0d", temp_receive_flit.flitData);
      receive_counter[i] <= receive_counter[i] + 1;
    endrule
  end

  rule done (clkCount == 100);
    $finish;
  endrule

endmodule
