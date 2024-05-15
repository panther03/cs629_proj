import FIFO::*;
import FIFOF::*;
import SpecialFIFOs::*;
import RegFile::*;
import RVUtil::*;
import Vector::*;
import KonataHelper::*;
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

interface Scoreboard;
    method Action insert(Bit#(5) dst);
    method Action remove(Bit#(5) dst);
    method ActionValue#(Bool) search1(Bit#(5) src);
    method ActionValue#(Bool) search2(Bit#(5) src);
    method ActionValue#(Bool) search3(Bit#(5) src);
endinterface

// TODO: ask about 2-bit scoreboard/WAW stall
module mkScoreboardBoolFlags(Scoreboard); 
    Vector#(32, Ehr#(2, Bool)) ready <- replicateM(mkEhr(True));

    method Action insert(Bit#(5) dst);
        ready[dst][1] <= False;
    endmethod

    method Action remove(Bit#(5) dst);
        ready[dst][0] <= True;
    endmethod

    method ActionValue#(Bool) search1(Bit#(5) src);
        return ready[src][1];
    endmethod

    method ActionValue#(Bool) search2(Bit#(5) src);
        return ready[src][1];
    endmethod

     method ActionValue#(Bool) search3(Bit#(5) src);
        return ready[src][1];
    endmethod
endmodule

// typedef struct { Bit#(4) byte_en; Bit#(32) addr; Bit#(32) data; } Mem deriving (Eq, FShow, Bits);
typedef struct { Bool isUnsigned; Bit#(2) size; Bit#(2) offset; Bool mmio; } MemBusiness deriving (Eq, FShow, Bits);

function Bool isMMIO(Bit#(32) addr);
    Bool x = case (addr) 
        32'hf000fff0: True;
        32'hf000fff4: True;
        32'hf000fff8: True;
        default: False;
    endcase;
    return x;
endfunction

typedef struct { Bit#(32) pc;
                 Bit#(32) ppc;
                 Bit#(1) epoch; 
                 Bit#(1) thread_id;
                 KonataId k_id; // <- This is a unique identifier per instructions, for logging purposes
             } F2D deriving (Eq, FShow, Bits);

typedef struct { 
    DecodedInst dinst;
    Bit#(32) pc;
    Bit#(32) ppc;
    Bit#(1) epoch;
    Bit#(32) rv1; 
    Bit#(32) rv2; 
    Bit#(1) thread_id;
    KonataId k_id; // <- This is a unique identifier per instructions, for logging purposes
    } D2E deriving (Eq, FShow, Bits);

typedef struct { 
    MemBusiness mem_business;
    Bit#(32) data;
    DecodedInst dinst;
    Bool poisoned;
    Bit#(1) thread_id;
    KonataId k_id; // <- This is a unique identifier per instructions, for logging purposes
} E2W deriving (Eq, FShow, Bits);

(* synthesize *)
module mkpipelined(RVIfc);
    // Interface with memory and devices
    FIFO#(Mem) toImem <- mkBypassFIFO;
    FIFO#(Mem) fromImem <- mkBypassFIFO;
    FIFO#(Mem) toDmem <- mkBypassFIFO;
    FIFOF#(Mem) fromDmem <- mkBypassFIFOF;
    FIFO#(Mem) toMMIO <- mkBypassFIFO;
    FIFO#(Mem) fromMMIO <- mkBypassFIFO;

    Reg#(Bit#(1)) lastThread <- mkReg(1);

    Ehr#(2, Bit#(32)) pcT0 <- mkEhr(0);
    Ehr#(2, Bit#(32)) pcT1 <- mkEhr(0);
    Ehr#(2, Bit#(1)) epochT0 <- mkEhr(0);
    Ehr#(2, Bit#(1)) epochT1 <- mkEhr(0);

    Vector#(32, Ehr#(2, Bit#(32))) rfT0 <- replicateM(mkEhr(32'h0000000));
    // TODO: figure out how to set a1 to 1 here
    Vector#(32, Ehr#(2, Bit#(32))) rfT1 <- replicateM(mkEhr(32'h0000000));
    Scoreboard scT0 <- mkScoreboardBoolFlags;
    Scoreboard scT1 <- mkScoreboardBoolFlags;

    Reg#(Bit#(32)) cyc <- mkReg(0);

	// Code to support Konata visualization
    String dumpFile = "output.log";
    let lfh <- mkReg(InvalidFile);
	Reg#(KonataId) fresh_id <- mkReg(0);
	Reg#(KonataId) commit_id <- mkReg(0);

	FIFO#(KonataId) retired <- mkFIFO;
	FIFO#(KonataId) squashed <- mkFIFO;

    FIFO#(F2D) f2d <- mkFIFO;
    FIFO#(D2E) d2e <- mkFIFO;
    FIFOF#(E2W) e2w <- mkFIFOF;

    Bool debug = False;
    Reg#(Bool) starting <- mkReg(True);
	rule do_tic_logging;
        if (starting) begin
            let f <- $fopen(dumpFile, "w") ;
            lfh <= f;
            $fwrite(f, "Kanata\t0004\nC=\t1\n");
            starting <= False;
        end
		konataTic(lfh);
	endrule

    rule init_t1_regfile if (starting);
        rfT1[10][0] <= 1;
    endrule

    // TODO: remove debugging logic
    rule cyc_count_debug;
        cyc <= cyc + 1;
    endrule
		
    rule fetchT0 if (!starting && (lastThread == 1));
        // Fetch PC including bypassed result from execute
        Bit#(32) pc_next = pcT0[1] + 4;

        // Update PC register based on calculated next
        // This will include the bypassed jump target
        pcT0[1] <= pc_next; 

        // Mem should also initiate a request from the bypass
        let req = Mem {byte_en: 0, addr: pcT0[1], data: ?};
        toImem.enq(req);

        // Trigger konata
        let iid <- fetch1Konata(lfh, fresh_id, 0);
        labelKonataLeft(lfh, iid, $format("0x%x: ", pcT0[1]));

        if (debug) $display("(cyc=%d) [Fetch] thread=0", cyc, fshow(pcT0[1]));

        // Enqueue to the next pipeline stage
        f2d.enq(F2D{
            pc: pc_next, // NEXT pc
            ppc: pcT0[1], // PREVIOUS pc
            epoch: epochT0[1],
            thread_id: 0,
            k_id: iid
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
        let iid <- fetch1Konata(lfh, fresh_id, 1);
        labelKonataLeft(lfh, iid, $format("0x%x: ", pcT1[1]));

        if (debug) $display("(cyc=%d) [Fetch] thread=1", cyc, fshow(pcT0[1]));

        // Enqueue to the next pipeline stage
        f2d.enq(F2D{
            pc: pc_next, // NEXT pc
            ppc: pcT1[1], // PREVIOUS pc
            epoch: epochT1[1],
            thread_id: 1,
            k_id: iid
        });
        lastThread <= ~lastThread;
    endrule

    rule decode if (!starting);
        // Check for operands being ready without dequeueing.
        // RS1 and RS2 need to be ready for RAW hazards,
        // while we need to wait on RD for a WAR hazard,
        // which here is only applicable when two insructions write to the same
        // register back-to-back and then after the register is read.
        let resp = fromImem.first();
        let instr = resp.data;
        let decodedInst = decodeInst(resp.data);
        let fetchedInstr = f2d.first();
        let thread = fetchedInstr.thread_id;
        let rs1_idx = getInstFields(instr).rs1;
        let rs2_idx = getInstFields(instr).rs2;
        let rd_idx = getInstFields(instr).rd;
        let rs1_rdy <- (thread == 1) ? scT1.search1(rs1_idx) : scT0.search1(rs1_idx);
        let rs2_rdy <- (thread == 1) ? scT1.search1(rs2_idx) : scT0.search2(rs2_idx);
        let rd_rdy <- (thread == 1) ? scT1.search3(rd_idx) : scT0.search3(rd_idx);

        //if (debug) $display("(cyc=%d) [Pre-Decode] [%d,%d,%d] ", cyc, rs1_rdy, rs2_rdy, rd_rdy, fshow(getInstFields(instr)));
     
        if ((rs1_rdy) && (rs2_rdy) && (rd_rdy || !decodedInst.valid_rd)) begin
            // Dequeue IMEM result with pipeline register, keeping them in-sync
            fromImem.deq();
            f2d.deq();

            if (debug) $display("(cyc=%d) [Decode] ", cyc, fshow(thread));

            // 0 is hard-wired to 0 val in RISC-V
            let rs1 = (rs1_idx == 0 ? 0 : ((thread == 1) ? rfT1[rs1_idx][1] : rfT0[rs1_idx][1]));
            let rs2 = (rs2_idx == 0 ? 0 : ((thread == 1) ? rfT1[rs2_idx][1] : rfT0[rs2_idx][1]));

            // RD is now busy in the scoreboard
            if (rd_idx != 0 && decodedInst.valid_rd) begin
                if (thread == 1) begin
                    scT1.insert(rd_idx);
                end else begin
                    scT0.insert(rd_idx);
                end
                // $display("(cyc=%d) inserting %d", cyc, rd_idx);
            end

            // To add a decode event in Konata you will likely do something like:
            decodeKonata(lfh, fetchedInstr.k_id);
            labelKonataLeft(lfh,fetchedInstr.k_id, $format("RD=%d | rf[RS1=%d]=%x | rf[RS2=%d]=%d", rd_idx, rs1_idx, rs1, rs2_idx, rs2));

            // Ready to execute; enqueue to next pipeline stage
            d2e.enq(D2E{
                dinst: decodedInst,
                pc: fetchedInstr.pc,
                ppc: fetchedInstr.ppc,
                epoch: fetchedInstr.epoch,
                rv1: rs1,
                rv2: rs2,
                thread_id: thread,
                k_id: fetchedInstr.k_id
            });
        end
    endrule

    rule execute if (!starting);
        // Dequeue from previous pipeline stage
        let decodedInstr = d2e.first();
        d2e.deq();
        let dInst = decodedInstr.dinst;
        let thread = decodedInstr.thread_id;

        // Mark instruction in konata
        let current_id = decodedInstr.k_id;
    	executeKonata(lfh, current_id);
        if (debug) $display("(cyc=%d) [Execute] ", cyc, fshow(thread));

		let imm = getImmediate(dInst);
        let rv1 = decodedInstr.rv1;
        let rv2 = decodedInstr.rv2;
		Bool mmio = False;
        let instr_pc = decodedInstr.ppc; // we reference from the CURRENT (i.e. previous) PC
		let data = execALU32(dInst.inst, decodedInstr.rv1, decodedInstr.rv2, imm, instr_pc);
		let isUnsigned = 0;
		let funct3 = getInstFields(dInst.inst).funct3;
		let size = funct3[1:0];
		let addr = rv1 + imm;
		Bit#(2) offset = addr[1:0];
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
		    addr = {addr[31:2], 2'b0};
		    isUnsigned = funct3[2];
		    let type_mem = (dInst.inst[5] == 1) ? byte_en : 0;
		    let req = Mem {byte_en : type_mem,
				       addr : addr,
				       data : data};
		    if (isMMIO(addr)) begin 
		        if (debug) $display("[Execute] MMIO", fshow(req));
				toMMIO.enq(req);
                labelKonataLeft(lfh,current_id, $format(" (MMIO)", fshow(req)));
    		    mmio = True;
		    end else begin 
                labelKonataLeft(lfh,current_id, $format(" (MEM)", fshow(req)));
    		    toDmem.enq(req);
		    end
		end
		else if (isControlInst(dInst)) begin
            labelKonataLeft(lfh,current_id, $format(" (CTRL)"));
            data = instr_pc + 4;
		end else begin 
            labelKonataLeft(lfh,current_id, $format(" (ALU)"));
		end
		let controlResult = execControl32(dInst.inst, rv1, rv2, imm, instr_pc);
		

        // Detect squashed instructions. We poison them so we can 
        // simply drop the instructions in writeback, freeing the 
        // scoreboard entry as we would normally.
        let poisoned = False;
        if (((thread == 1) && epochT1[0] != decodedInstr.epoch) || ((thread == 0) && epochT0[0] != decodedInstr.epoch)) begin
            squashed.enq(current_id);
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
            dinst: dInst,
            k_id: current_id,
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
        let current_id = executedInstr.k_id;
        let data = executedInstr.data;
        let mem_business = executedInstr.mem_business;
        let poisoned = executedInstr.poisoned;

        if (!poisoned) begin
            writebackKonata(lfh,current_id);
            retired.enq(current_id);
        end
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
		if(debug && !poisoned) begin
             $display("(cyc=%d) [Writeback]", cyc, fshow(thread));
        end
        // TODO: fix this fault logic so bluespec doesnt complain
        //if (!dInst.legal) begin
		//	if (debug) $display("[Writeback] Illegal Inst, Drop and fault: ", fshow(dInst));
		//	pc[0] <= 0;	// Fault
	    //end
		if (dInst.valid_rd) begin
            let rd_idx = fields.rd;
            if (rd_idx != 0) begin 
                if (!poisoned) begin 
                    if (thread == 1) begin
                        rfT1[rd_idx][0] <= data;
                    end else begin
                        rfT0[rd_idx][0] <= data;
                    end
                end
                // $display("(cyc=%d) removing %d", cyc, rd_idx);
                if (thread == 1) begin
                    scT1.remove(rd_idx);
                end else begin
                    scT0.remove(rd_idx);
                end
            end
		end

	endrule
		

	// ADMINISTRATION:

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
