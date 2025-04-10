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

`include "ucsbece154b_defines.vh"

// Pipeline Registers
// fetch to decode 
reg [31:0] PCF, InstrD;

// decode to execute
reg [31:0] Rd1E, Rd2E, PCE, ImmExtE, PCPlus4E, PCTargetE;
reg [4:0] Rs1E, Rs2E, RdE;


// execute to memory


// memory to writeback

// Instruction Fetch Stage

wire [31:0] PCNextF;

assign PCPlus4 = PCF_o + 32'b100; //current PC + 4
assign PCTarget = PCF_o + ImmExtE; // uses the current PC + Immediate to get to the target address / instruction
assign PCNextF = (PCSrcE_i) ? PCTargetE : PCPlus4; // mux that either transfers the PC








endmodule


