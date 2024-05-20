// Pipelined processor, more amenable to synthesis version.
// Removed giant Ehr scoreboard  + regfile.

//`define KONATA_ENABLE
//`define DEBUG_ENABLE

import Assert::*;
import FIFO::*;
import FIFOF::*;
import SpecialFIFOs::*;
import RegFile::*;
import RVUtil::*;
import Vector::*;
`ifdef KONATA_ENABLE
import KonataHelper::*;
`endif
import Printf::*;
import Ehr::*;

import CacheInterface::*;

typedef struct { Bit#(4) byte_en; Bit#(32) addr; Bit#(32) data; } Mem deriving (Eq, FShow, Bits);


interface RVIfc;
    method ActionValue#(Mem) getIReq();
    method Action getIResp(Mem a);
    method ActionValue#(Mem) getDReq();
    method Action getDResp(Mem a);
    method ActionValue#(Mem) getMMIOReq();
    method Action getMMIOResp(Mem a);
endinterface

// typedef struct { Bit#(4) byte_en; Bit#(32) addr; Bit#(32) data; } Mem deriving (Eq, FShow, Bits);
typedef struct { Bool isUnsigned; Bit#(2) size; Bit#(2) offset; Bool mmio; } MemBusiness deriving (Eq, FShow, Bits);

function Bool isMMIO(Bit#(32) addr);
    /*Bool x = case (addr) 
        32'hf000fff0: True;
        32'hf000fff4: True;
        32'hf000fff8: True;
        default: False;
    endcase;*/
    // simplifying assumption
    return addr[31:29] == 3'h7;
endfunction

typedef struct { Bit#(32) pc;
                 Bit#(32) ppc;
                 Bit#(1) epoch; 
                 Bit#(1) thread_id;
`ifdef KONATA_ENABLE
                 KonataId k_id; // <- This is a unique identifier per instructions, for logging purposes
`endif
             } F2D deriving (Eq, FShow, Bits);

typedef struct { 
    DecodedInst dinst;
    Bit#(32) pc;
    Bit#(32) ppc;
    Bit#(1) epoch;
    Bit#(32) rv1; 
    Bit#(32) rv2; 
    Bit#(1) thread_id;
`ifdef KONATA_ENABLE
    KonataId k_id; // <- This is a unique identifier per instructions, for logging purposes
`endif
    } D2E deriving (Eq, FShow, Bits);

typedef struct { 
    MemBusiness mem_business;
    Bit#(32) data;
    Bool data_valid;
    DecodedInst dinst;
    Bool poisoned;
    Bit#(1) thread_id;
`ifdef KONATA_ENABLE
    KonataId k_id; // <- This is a unique identifier per instructions, for logging purposes
`endif
} E2W deriving (Eq, FShow, Bits);

typedef struct {
    Bit#(32) data;
    // it's actually unecessary, as this is an invariant; we don't try to forward invalid data
    Bool data_valid;
    Bit#(1) thread_id;
    Bit#(5) rd_idx;
    Bool rd_valid;
    Bool is_mem_inst;
} ForwardingPath deriving (Eq, FShow, Bits);

(* synthesize *)
module mkPipelined(RVIfc);
    // Interface with memory and devices
    FIFO#(Mem) toImem <- mkBypassFIFO;
    FIFO#(Mem) fromImem <- mkBypassFIFO;
    FIFO#(Mem) toDmem <- mkBypassFIFO;
    FIFOF#(Mem) fromDmem <- mkBypassFIFOF;
    FIFO#(Mem) toMMIO <- mkFIFO;
    FIFO#(Mem) fromMMIO <- mkBypassFIFO;

    Reg#(Bit#(1)) lastThread <- mkReg(1);

    Ehr#(2, Bit#(32)) pcT0 <- mkEhr(0);
    Ehr#(2, Bit#(32)) pcT1 <- mkEhr(0);
    Ehr#(2, Bit#(1)) epochT0 <- mkEhr(0);
    Ehr#(2, Bit#(1)) epochT1 <- mkEhr(0);

    Vector#(32, Reg#(Bit#(32))) rfT0 <- replicateM(mkReg(32'h0000000));
    Vector#(32, Reg#(Bit#(32))) rfT1 <- replicateM(mkReg(32'h0000000));

    FIFO#(F2D) f2d <- mkFIFO;
    FIFOF#(D2E) d2e <- mkFIFOF;
    FIFOF#(E2W) e2w <- mkFIFOF;

    Wire#(ForwardingPath) wbForward <- mkWire();
    RWire#(ForwardingPath) wbForwardOvr <- mkRWire();
    Reg#(ForwardingPath) wbForwardR <- mkReg(unpack(0));
    Wire#(ForwardingPath) exForward <- mkWire;

    Reg#(Bool) starting <- mkReg(True);

    rule init_t1_regfile if (starting);
        rfT1[10] <= 1;
        starting <= False;
    endrule

    Reg#(Bit#(32)) cyc <- mkReg(0);

`ifdef KONATA_ENABLE
	// Code to support Konata visualization
    String dumpFile = "output.log";
    let lfh <- mkReg(InvalidFile);
	Reg#(KonataId) fresh_id <- mkReg(0);
	Reg#(KonataId) commit_id <- mkReg(0);

	FIFO#(KonataId) retired <- mkFIFO;
	FIFO#(KonataId) squashed <- mkFIFO;

    rule do_tic_logging;
        if (starting) begin
            let f <- $fopen(dumpFile, "w") ;
            lfh <= f;
            $fwrite(f, "Kanata\t0004\nC=\t1\n");
        end
		konataTic(lfh);
	endrule
`endif

`ifdef DEBUG_ENABLE
    
    rule cyc_count_debug;
        cyc <= cyc + 1;
    endrule
`endif

		
    rule fetchT0 if (!starting && (lastThread == 1));
        // Fetch PC including bypassed result from execute
        Bit#(32) pc_next = pcT0[1] + 4;

        // Update PC register based on calculated next
        // This will include the bypassed jump target
        pcT0[1] <= pc_next; 

        // Mem should also initiate a request from the bypass
        let req = Mem {byte_en: 0, addr: pcT0[1], data: ?};
        toImem.enq(req);

`ifdef KONATA_ENABLE
        // Trigger konata
        let iid <- fetch1Konata(lfh, fresh_id, 0);
        labelKonataLeft(lfh, iid, $format("0x%x: ", pcT0[1]));
`endif

`ifdef DEBUG_ENABLE 
        $display("(cyc=%d) [Fetch] thread=0", cyc, fshow(pcT0[1]));
`endif

        // Enqueue to the next pipeline stage
        f2d.enq(F2D{
            pc: pc_next, // NEXT pc
            ppc: pcT0[1], // PREVIOUS pc
`ifdef KONATA_ENABLE
            k_id: iid,
`endif
            epoch: epochT0[1],
            thread_id: 0
        });
        lastThread <= ~lastThread;
    endrule

    rule fetchT1 if (!starting && (lastThread == 0));
        // Fetch PC including bypassed result from execute
        Bit#(32) pc_next = pcT1[1] + 4;

        // Update PC register based on calculated next
        // This will include the bypassed jump target
        pcT1[1] <= pc_next; 

        // Mem should also initiate a request from the bypass
        let req = Mem {byte_en: 0, addr: pcT1[1], data: ?};
        toImem.enq(req);

        // Trigger konata
`ifdef KONATA_ENABLE
        let iid <- fetch1Konata(lfh, fresh_id, 1);
        labelKonataLeft(lfh, iid, $format("0x%x: ", pcT1[1]));
`endif

`ifdef DEBUG_ENABLE 
        $display("(cyc=%d) [Fetch] thread=1", cyc, fshow(pcT1[1]));
`endif

        // Enqueue to the next pipeline stage
        f2d.enq(F2D{
            pc: pc_next, // NEXT pc
            ppc: pcT1[1], // PREVIOUS pc
`ifdef KONATA_ENABLE
            k_id: iid,
`endif
            epoch: epochT1[1],
            thread_id: 1
        });
        lastThread <= ~lastThread;
    endrule

    function Bool prodMatches(ForwardingPath fp, Bit#(5) op_idx, Bit#(1) thread);
        return (op_idx != 0) && (fp.rd_valid) && (fp.thread_id == thread) && (fp.rd_idx == op_idx);
    endfunction

    rule decode if (!starting);
        let resp = fromImem.first();
        let instr = resp.data;
        let decodedInst = decodeInst(resp.data);
        let fetchedInstr = f2d.first();
        let thread = fetchedInstr.thread_id;
        let rs1_idx = getInstFields(instr).rs1;
        let rs2_idx = getInstFields(instr).rs2;
        let rd_idx = getInstFields(instr).rd;
        
        //let wbForwardRelevant = wbForward[2].rd_valid && (wbForward[2].thread_id == thread) ;
        //let rs1_rdy = (rs1_idx == 0) || !wbForwardRelevant || (wbForward[2].data_valid) || (wbForward[2].rd_idx != rs1_idx);
        //let rs2_rdy = (rs2_idx == 0) || !wbForwardRelevant || (wbForward[2].data_valid) || (wbForward[2].rd_idx != rs2_idx);

        // A load which immediately preceeds this instruction requires 1 bubble.
        // We let backpressure take care of the rest: By the time we get to execute, we will have the forwarding result
        // available in either wbForward or wbForwardR.
        let stall = exForward.is_mem_inst && (prodMatches(exForward, rs1_idx, thread) || prodMatches(exForward, rs2_idx, thread));

`ifdef DEBUG_ENABLE
        $display("(cyc=%d) [Pre-Decode] [stall=%d] ", cyc, stall, fshow(getInstFields(instr)));
`endif
     
        if (!stall) begin
            // Dequeue IMEM result with pipeline register, keeping them in-sync
            fromImem.deq();
            f2d.deq();

`ifdef DEBUG_ENABLE
            $display("(cyc=%d) [Decode] pc=%x ", cyc, fetchedInstr.ppc,fshow(thread));
`endif
            
            // 0 is hard-wired to 0 val in RISC-V
            let rs1 = (thread == 1) ? rfT1[rs1_idx] : rfT0[rs1_idx];
            let rs2 = (thread == 1) ? rfT1[rs2_idx] : rfT0[rs2_idx];

`ifdef KONATA_ENABLE
                decodeKonata(lfh, fetchedInstr.k_id);
                /*labelKonataLeft(lfh,fetchedInstr.k_id, $format("RD=%d | rf[RS1=%d]=%x | rf[RS2=%d]=%x", rd_idx, rs1_idx, rs1, rs2_idx, rs2));*/
`endif

            // Ready to execute; enqueue to next pipeline stage
            d2e.enq(D2E{
                dinst: decodedInst,
                pc: fetchedInstr.pc,
                ppc: fetchedInstr.ppc,
`ifdef KONATA_ENABLE
                k_id: fetchedInstr.k_id,
`endif
                epoch: fetchedInstr.epoch,
                rv1: rs1,
                rv2: rs2,
                thread_id: thread
            });
        end
    endrule

    rule execute if (!starting);
        // Dequeue from previous pipeline stage
        let decodedInstr = d2e.first();
        d2e.deq();
        let dInst = decodedInstr.dinst;
        let thread = decodedInstr.thread_id;

`ifdef KONATA_ENABLE
        // Mark instruction in konata
        let current_id = decodedInstr.k_id;
    	executeKonata(lfh, current_id);
`endif


		let imm = getImmediate(dInst);
        let fields = getInstFields(dInst.inst);

        // Forwarding
        let rs1 = fields.rs1;
        let rv1_wbf_m = prodMatches(wbForward, rs1, thread);
        let rv1_wbf_r_m = prodMatches(wbForwardR, rs1, thread);
        let rv1 = rv1_wbf_m ? wbForward.data : (rv1_wbf_r_m ? wbForwardR.data : decodedInstr.rv1);

        let rs2 = fields.rs2;
        let rv2_wbf_m = prodMatches(wbForward, rs2, thread);
        let rv2_wbf_r_m = prodMatches(wbForwardR, rs2, thread);
        let rv2 = rv2_wbf_m ? wbForward.data : (rv2_wbf_r_m ? wbForwardR.data : decodedInstr.rv2);

        // verify assumptions
        dynamicAssert(!rv1_wbf_m || wbForward.data_valid, "RV1 forwarded invalid data from wbForward");
        dynamicAssert(!rv1_wbf_r_m || wbForwardR.data_valid, "RV1 forwarded invalid data from wbForwardR");
        dynamicAssert(!rv2_wbf_m || wbForward.data_valid, "RV2 forwarded invalid data from wbForward");
        dynamicAssert(!rv2_wbf_r_m || wbForwardR.data_valid, "RV2 forwarded invalid data from wbForwardR");
        
        Bool mmio = False;
        let instr_pc = decodedInstr.ppc; // we reference from the CURRENT (i.e. previous) PC
		let data = execALU32(dInst.inst, rv1, rv2, imm, instr_pc);
        let data_valid = True;
		let isUnsigned = 0;
		let funct3 = fields.funct3;
		let size = funct3[1:0];
		let addr = rv1 + imm;
		Bit#(2) offset = addr[1:0];

`ifdef DEBUG_ENABLE
        $display("(cyc=%d) [Execute] pc=%x data=%d; rv1=%d; rv2=%d ", cyc, instr_pc, data, rv1, rv2, fshow(thread));
`endif

		if (isMemoryInst(dInst)) begin
			// Technical details for load byte/halfword/word
		    let shift_amount = {offset, 3'b0};
		    let byte_en = 0;
		    case (size) matches
			2'b00: byte_en = 4'b0001 << offset;
			2'b01: byte_en = 4'b0011 << offset;
			2'b10: byte_en = 4'b1111 << offset;
		    endcase
		    data = rv2 << shift_amount;
            data_valid = False;
		    addr = {addr[31:2], 2'b0};
		    isUnsigned = funct3[2];
		    let type_mem = (dInst.inst[5] == 1) ? byte_en : 0;
		    let req = Mem {byte_en : type_mem,
				       addr : addr,
				       data : data};
		    if (isMMIO(addr)) begin 
`ifdef DEBUG_ENABLE
		        $display("[Execute] MMIO", fshow(req));
`endif
				toMMIO.enq(req);
`ifdef KONATA_ENABLE
                labelKonataLeft(lfh,current_id, $format(" (MMIO)", fshow(req)));
`endif
    		    mmio = True;
		    end else begin 
`ifdef KONATA_ENABLE
                labelKonataLeft(lfh,current_id, $format(" (MEM)", fshow(req)));
`endif
    		    toDmem.enq(req);
		    end
		end
		else if (isControlInst(dInst)) begin
`ifdef KONATA_ENABLE
            labelKonataLeft(lfh,current_id, $format(" (CTRL)"));
`endif
            data = instr_pc + 4;
            data_valid = False;
		end else begin 
`ifdef KONATA_ENABLE
            labelKonataLeft(lfh,current_id, $format(" (ALU)"));
`endif
		end
		let controlResult = execControl32(dInst.inst, rv1, rv2, imm, instr_pc);
		

        // Detect squashed instructions. We poison them so we can 
        // simply drop the instructions in writeback, freeing the 
        // scoreboard entry as we would normally.
        let poisoned = False;
        if (((thread == 1) && epochT1[0] != decodedInstr.epoch) || ((thread == 0) && epochT0[0] != decodedInstr.epoch)) begin
`ifdef KONATA_ENABLE
            squashed.enq(current_id);
`endif
            poisoned = True;

        // Poisoned instructions can't invalidate the epoch!
        // Also, we can just use taken as a trigger for a misprediction, since we always predict not taken.
        end else if (controlResult.taken) begin  
            if (thread == 1) begin
                pcT1[0] <= controlResult.nextPC; 
                epochT1[0] <= ~epochT1[0];
            end else begin
                pcT0[0] <= controlResult.nextPC; 
                epochT0[0] <= ~epochT0[0];
            end
        end

        e2w.enq(E2W{
            mem_business: MemBusiness{isUnsigned: unpack(isUnsigned), size: size, offset: offset, mmio: mmio},
            data: data,
            data_valid: data_valid,
            dinst: dInst,
`ifdef KONATA_ENABLE
            k_id: current_id,
`endif
            thread_id: thread,
            poisoned: poisoned
        });
        
    endrule

    rule writeback if (!starting);
        // Dequeue from previous pipeline stage
        // $display("E2W: %d; memResp: %d", e2w.notEmpty(), fromDmem.notEmpty());
        let executedInstr = e2w.first();
        e2w.deq();
        let dInst = executedInstr.dinst;
        let thread = executedInstr.thread_id;
        let data = executedInstr.data;
        let mem_business = executedInstr.mem_business;
        let poisoned = executedInstr.poisoned;

        let fields = getInstFields(dInst.inst);
        if (isMemoryInst(dInst)) begin // (* // write_val *)
            let resp = ?;
		    if (mem_business.mmio) begin 
                resp = fromMMIO.first();
		        fromMMIO.deq();
		    end else begin 
                resp = fromDmem.first();
		        fromDmem.deq();
		    end
            let mem_data = resp.data;
            mem_data = mem_data >> {mem_business.offset ,3'b0};
            case ({pack(mem_business.isUnsigned), mem_business.size}) matches
	     	3'b000 : data = signExtend(mem_data[7:0]);
	     	3'b001 : data = signExtend(mem_data[15:0]);
	     	3'b100 : data = zeroExtend(mem_data[7:0]);
	     	3'b101 : data = zeroExtend(mem_data[15:0]);
	     	3'b010 : data = mem_data;
             endcase
		end

`ifdef KONATA_ENABLE
        let current_id = executedInstr.k_id;
        if (!poisoned) begin
            writebackKonata(lfh,current_id);
            retired.enq(current_id);

            if (dInst.valid_rd) begin
              labelKonataLeft(lfh,current_id, $format("RF [%d]=%d", fields.rd, data));
            end
        end
`endif

`ifdef DEBUG_ENABLE
		if(!poisoned) begin
             $display("(cyc=%d) [Writeback] data=%d t=", cyc, data, fshow(thread));
        end
`endif
        // TODO: fix this fault logic so bluespec doesnt complain
        //if (!dInst.legal) begin
		//	if (debug) $display("[Writeback] Illegal Inst, Drop and fault: ", fshow(dInst));
		//	pc[0] <= 0;	// Fault
	    //end
		if (dInst.valid_rd) begin
            let rd_idx = fields.rd;
            if (rd_idx != 0 && !poisoned) begin
                if (thread == 1) begin
                    rfT1[rd_idx] <= data;
                end else begin
                    rfT0[rd_idx] <= data;
                end

                wbForwardOvr.wset(ForwardingPath {
                    data: data,
                    data_valid: True,
                    thread_id: thread,
                    rd_idx: rd_idx,
                    rd_valid: True,
                    is_mem_inst: ?
                });
            end
		end
	endrule

    rule wbForwardApply if (!starting);
        if (e2w.notEmpty()) begin
            let executedInstr = e2w.first();
            wbForward <= ForwardingPath {
                data: executedInstr.data,
                data_valid: executedInstr.data_valid,
                thread_id: executedInstr.thread_id,
                rd_idx: getInstFields(executedInstr.dinst.inst).rd,
                rd_valid: executedInstr.dinst.valid_rd && !executedInstr.poisoned,
                is_mem_inst: ?
            };
        end else begin
            wbForward <= unpack(0);
        end
    endrule

    rule exForwardApply if (!starting);
        if (d2e.notEmpty()) begin
            let decodedInstr = d2e.first();
            exForward <= ForwardingPath {
                data: 0,
                data_valid: False,
                thread_id: decodedInstr.thread_id,
                rd_idx: getInstFields(decodedInstr.dinst.inst).rd,
                rd_valid: decodedInstr.dinst.valid_rd,
                is_mem_inst: isMemoryInst(decodedInstr.dinst)
            };
        end else begin
            exForward <= unpack(0);
        end
    endrule

    rule wbForwardCanonicalize if (!starting);
        wbForwardR <= fromMaybe(wbForward, wbForwardOvr.wget());
    endrule		

	// ADMINISTRATION:

`ifdef KONATA_ENABLE
    rule administrative_konata_commit;
		    retired.deq();
		    let f = retired.first();
		    commitKonata(lfh, f, commit_id);
	endrule
		
	rule administrative_konata_flush;
		    squashed.deq();
		    let f = squashed.first();
		    squashKonata(lfh, f);
	endrule
`endif
		
    method ActionValue#(Mem) getIReq();
		toImem.deq();
		return toImem.first();
    endmethod
    method Action getIResp(Mem a);
    	fromImem.enq(a);
    endmethod
    method ActionValue#(Mem) getDReq();
		toDmem.deq();
		return toDmem.first();
    endmethod
    method Action getDResp(Mem a);
		fromDmem.enq(a);
    endmethod
    method ActionValue#(Mem) getMMIOReq();
		toMMIO.deq();
		return toMMIO.first();
    endmethod
    method Action getMMIOResp(Mem a);
		fromMMIO.enq(a);
    endmethod
endmodule