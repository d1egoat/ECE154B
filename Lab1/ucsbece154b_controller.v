// ucsbece154b_controller.v
// ECE 154B, RISC-V pipelined processor 
// All Rights Reserved
// Copyright (c) 2024 UCSB ECE
// Distribution Prohibited

// EDIT HERE 


module ucsbece154b_controller (
    input                clk, reset,
    input         [6:0]  op_i, 
    input         [2:0]  funct3_i,
    input                funct7b5_i,
    input 	             ZeroE_i,
    input         [4:0]  Rs1D_i,
    input         [4:0]  Rs2D_i,
    input         [4:0]  Rs1E_i,
    input         [4:0]  Rs2E_i,
    input         [4:0]  RdE_i,
    input         [4:0]  RdM_i,
    input         [4:0]  RdW_i,
    output wire		     StallF_o,  
    output wire          StallD_o,
    output wire          FlushD_o,
    output wire    [2:0] ImmSrcD_o, // extended to support jal 
    output wire          PCSrcE_o,
    output reg     [2:0] ALUControlE_o,
    output reg           ALUSrcE_o,
    output wire          FlushE_o,
    output reg     [1:0] ForwardAE_o,
    output reg     [1:0] ForwardBE_o,
    output reg           MemWriteM_o,
    output reg          RegWriteW_o,
    output reg    [1:0] ResultSrcW_o, 
    output reg    [1:0] ResultSrcM_o
);


 `include "ucsbece154b_defines.vh"

 always @ * begin
    // default values for I-type instructions
    ImmSrcD_o = imm_Itype; // I-type immediate
    PCSrcE_o = 1'b0; // default to PCSrc = 0 since we are not jumping or branching
    ALUSrcE_o = 1'b1; // default to ALUSrc = 1 since we are using I-type instructions
    MemWriteM_o = 1'b0; // default to MemWrite = 0 for I-type since we are not writing to memory
    ALUControlE_o = AluControl_add; // default to addition for I-type instructions
    ResultSrcW_o = MuxResult_aluout; // default to ALU result for I-type instructions
    branch = 1'b0; // default to branch = 0 for I-type instructions
    jump = 1'b0; // default to jump = 0 for I-type instructions
    ALUOp = 2'b00; // default to ALUOp = 0 for I-type instructions
    RegWreiteW_o = 1'b1; // default to write

    case (op_i)
        instr_jal_op: begin // JAL instruction
            ImmSrcD_o = imm_Jtype; // JAL immediate
            AluSrc_o = 1'bx // set ALUSrc to x for JAL instruction
            branch = 1'b0; // no branch for JAL instruction
            jump = 1'b1; // set jump to 1 for JAL instruction
            PCSrcE_o = PCTarget; // set PCSrc to target address for JAL instruction
            AluOp = ALUop_dc // set ALUOp to x for JAL instruction   
            FlushD_o = 1'b1; // flush the instruction in the decode stage
            FlushE_o = 1'b1; // flush the instruction in the execute stage
            MemWrite_o = 1'b0; // no memory write for JAL instruction
            ResultSrc_o = MuxPC_PCPlus4; // set ResultSrc to PC + 4 for JAL instruction
            RegWriteW_o = 1'b1; // set RegWrite to 1 for JAL instruction
        end
    endcase
 end 
    
    


endmodule

