// ucsbece154b_datapath.v
// ECE 154B, RISC-V pipelined processor 
// All Rights Reserved
// Copyright (c) 2024 UCSB ECE
// Distribution Prohibited

// EDIT HERE 


module ucsbece154b_datapath (
    input                clk, reset,
    input                PCSrcE_i,
    input                StallF_i,
    output reg    [31:0] PCF_o,
    input                StallD_i,
    input                FlushD_i,
    input         [31:0] InstrF_i,
    output wire    [6:0] op_o,
    output wire    [2:0] funct3_o,
    output wire          funct7b5_o,
    input                RegWriteW_i,
    input          [2:0] ImmSrcD_i,
    output wire    [4:0] Rs1D_o,
    output wire    [4:0] Rs2D_o,
    input  wire          FlushE_i,
    output reg     [4:0] Rs1E_o,
    output reg     [4:0] Rs2E_o, 
    output reg     [4:0] RdE_o, 
    input                ALUSrcE_i,
    input          [2:0] ALUControlE_i,
    input          [1:0] ForwardAE_i,
    input          [1:0] ForwardBE_i,
    output               ZeroE_o,
    output reg     [4:0] RdM_o, 
    output reg    [31:0] ALUResultM_o,
    output reg    [31:0] WriteDataM_o,
    input         [31:0] ReadDataM_i,
    input          [1:0] ResultSrcW_i,
    output reg     [4:0] RdW_o,
    input          [1:0] ResultSrcM_i
);
ß
`include "ucsbece154b_defines.vh"

// Fetch and Decode Stage Registers 
reg [31:0] PCD; // PC in Decode 
reg [31:0] InstrD; // Instruction in Decode 

reg [31:0] PCPlus4E, PCPlus4M, PCPlus4W; // PC + 4 in Execute, Memory, Writeback



wire [31:0] imm_J;
wire [31:0] target_address = PCD + imm_J; // PC + JAL immediate
assign imm_J = {12{InstrD[31]}, InstrD[19:12], InstrD[20], InstrD[30:21], 1'b0}; // JAL immediate



always @(posedge clk) begin
    if (reset)
        PCF_o <= pc_start // reset PC to start address
    else if (PCSrcE_i)
        PCF_o <= target_address; // set PC to target address for JAL instruction
    else
        PCF_o <= PCF_o + 4; // increment PC nomrally 
end

assign op_o InstrD[6:0]; // opcode from instruction

always @(posedge clk) begin
    PCPlus4E <= PCD + 4; // PC + 4 in Execute stage
    PCPlus4M <= PCPlus4E; // PC + 4 in Memory stage
    PCPlus4W <= PCPlus4M; // PC + 4 in Writeback stage
end


// Mux to write PC + 4 to the destination register 
wire [31:0] ResultW = (ResultSrcW_i == MuxResult_PCPlus4) ? PCPlus4W : 32'b0; // Result for Writeback stage

// update destination register 
always @(posedge clk) begin
    if (RegWriteW_i)
    RdW_o <= InstrD[11:7]; // write register in Writeback stage
end 

always @(posedge clk) begin
    PCD <= PCF_o; // update PC in Decode stage
    InstrD <= InstrF_i; // update instruction in Decode stage
end 

endmodule


