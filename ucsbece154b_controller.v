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



 wire branch;
 wire jump;
 wire [1:0] ALUOp;


reg [11:0] controls;

// Main control decoder
always @* begin
    case (op_i)
        instr_jal_op:       controls = 12'b1_011_1_0_10_0_xx_1;  // JAL
        instr_jalr_op:      controls = 12'b1_000_1_0_10_0_xx_1;  // JALR
        instr_lui_op:       controls = 12'b1_100_1_0_11_0_xx_0;  // LUI
        instr_lw_op:        controls = 12'b1_000_1_0_01_0_00_0;  // LW
        instr_sw_op:        controls = 12'b0_001_1_1_xx_0_00_0;  // SW
        instr_Rtype_op:     controls = 12'b1_xxx_0_0_00_0_10_0;  // R-type
        instr_beq_op:       controls = 12'b0_010_0_0_xx_1_01_0;  // BEQ
        instr_ItypeALU_op:  controls = 12'b1_000_1_0_00_0_10_0;  // I-type ALU
        default: begin	    
            controls = 12'bx_xxx_x_x_xx_x_xx_x;
            `ifdef SIM
                $warning("Unsupported op given: %h", op_i);
            `endif
        end 
    endcase

    RegWriteW_o = controls[11];    // register write
    ALUSrcE_o = controls[7];       // ALU source
    MemWriteM_o = controls[6];     // memory write
    ResultSrcW_o = controls[5:4];  // result source
end

// ALU control decoder
always @* begin
    case(ALUOp)
        ALUop_mem: ALUControlE_o = ALUcontrol_add;  // LW/SW
        ALUop_beq: ALUControlE_o = ALUcontrol_sub;  // BEQ
        ALUop_other: begin  // R-type/I-type
            case(funct3_i)
                instr_addsub_funct3: ALUControlE_o = funct7b5_i ? 
                                                   ALUcontrol_sub : ALUcontrol_add;
                instr_slt_funct3:    ALUControlE_o = ALUcontrol_slt;
                instr_or_funct3:     ALUControlE_o = ALUcontrol_or;
                instr_and_funct3:    ALUControlE_o = ALUcontrol_and;
                default: begin
                    ALUControlE_o = 3'bxxx;
                    `ifdef SIM
                        $warning("Unsupported funct3 given: %h", funct3_i);
                    `endif
                end
            endcase
        end
        default: begin
            ALUControlE_o = 3'bxxx;
            `ifdef SIM
                $warning("Unsupported ALUop given: %h", ALUOp);
            `endif
        end
    endcase
end

// Control signal assignments
assign branch = controls[3];
assign ALUOp = controls[2:1];
assign jump = controls[0] | (op_i == instr_jalr_op);
assign PCSrcE_o = (branch & ZeroE_i) | jump;
assign ImmSrcD_o = controls[10:8];
assign FlushD_o = jump;
assign FlushE_o = jump;

// Hazard detection
assign StallF_o = 1'b0;  // No stalling in fetch stage
assign StallD_o = 1'b0;  // No stalling in decode stage

// Forwarding logic
always @* begin
    // Forward A
    if (Rs1E_i != 5'b0) begin
        if (RegWriteW_o && (RdW_i == Rs1E_i))
            ForwardAE_o = 2'b01;  // Forward from Writeback
        else if (MemWriteM_o && (RdM_i == Rs1E_i))
            ForwardAE_o = 2'b10;  // Forward from Memory
        else
            ForwardAE_o = 2'b00;  // No forwarding
    end else
        ForwardAE_o = 2'b00;  // x0 doesn't need forwarding

    // Forward B
    if (Rs2E_i != 5'b0) begin
        if (RegWriteW_o && (RdW_i == Rs2E_i))
            ForwardBE_o = 2'b01;  // Forward from Writeback
        else if (MemWriteM_o && (RdM_i == Rs2E_i))
            ForwardBE_o = 2'b10;  // Forward from Memory
        else
            ForwardBE_o = 2'b00;  // No forwarding
    end else
        ForwardBE_o = 2'b00;  // x0 doesn't need forwarding
end
endmodule

