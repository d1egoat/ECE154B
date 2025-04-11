// ucsbece154b_datapath.v
// ECE 154B, RISC-V pipelined processor 
// All Rights Reserved
// Copyright (c) 2024 UCSB ECE
// Distribution Prohibited

// EDIT HERE 


module ucsbece154b_datapath (
    input                clk, reset, 
    input                PCSrcE_i, // Execute
    input                StallF_i, // Fetch
    output reg    [31:0] PCF_o, // Fetch
    input                StallD_i, // Decode
    input                FlushD_i,  // Decode
    input         [31:0] InstrF_i, // Fetch
    output wire    [6:0] op_o, // Decode
    output wire    [2:0] funct3_o,  // Decode
    output wire          funct7b5_o,    // Decode
    input                RegWriteW_i, // Writeback
    input          [2:0] ImmSrcD_i, // Decode
    output wire    [4:0] Rs1D_o,    // Decode
    output wire    [4:0] Rs2D_o,   // Decode
    input  wire          FlushE_i,  // Execute
    output reg     [4:0] Rs1E_o, // Execute
    output reg     [4:0] Rs2E_o,    // Execute
    output reg     [4:0] RdE_o,  // Execute
    input                ALUSrcE_i, // Execute
    input          [2:0] ALUControlE_i, // Execute
    input          [1:0] ForwardAE_i, // Execute
    input          [1:0] ForwardBE_i, // Execute
    output               ZeroE_o,   // Execute
    output reg     [4:0] RdM_o,  // Memory
    output reg    [31:0] ALUResultM_o, // Memory
    output reg    [31:0] WriteDataM_o, // Memory
    input         [31:0] ReadDataM_i, // Memory
    input          [1:0] ResultSrcW_i, // Writeback
    output reg     [4:0] RdW_o, // Writeback
    input          [1:0] ResultSrcM_i // Memory
);

`include "ucsbece154b_defines.vh"

// Pipeline registers
// Fetch -> Decode
reg [31:0] PCF, PCPlus4F;
reg [31:0] InstrD;

// Decode -> Execute
reg [31:0] PCPlus4D;
reg [31:0] ImmExtD, ImmExtE;
reg [31:0] Rd1D, Rd2D;
reg [4:0] Rs1D, Rs2D, RdD;

// Execute -> Memory
reg [31:0] ALUResultE, WriteDataE, PCPlus4E;
reg [4:0] RdE;

// Memory -> Writeback
reg [31:0] ALUResultM, ReadDataM, PCPlus4M;
reg [4:0] RdM;
reg [31:0] ResultW;

// Internal signals
wire [31:0] RD1, RD2;        // Register file outputs
wire [31:0] SrcAE, SrcBE;    // ALU inputs
wire [31:0] ImmExt;          // Immediate value
wire [31:0] PCTargetE;
wire [31:0] PCNextF;

// Instruction Fetch Stage
always @(posedge clk or posedge reset) begin
    if (reset) begin
        PCF <= pc_start;
        PCPlus4F <= 0;
    end else if (!StallF_i) begin
        PCF <= PCNextF;
        PCPlus4F <= PCF + 4;
    end
end

assign PCNextF = PCSrcE_i ? PCTargetE : PCPlus4F;

// Pipeline Register: Fetch -> Decode
always @(posedge clk) begin
    if (FlushD_i) begin
        InstrD <= 32'h00000013;  // NOP instruction
        PCPlus4D <= 0;
    end else if (!StallD_i) begin
        InstrD <= InstrF_i;
        PCPlus4D <= PCPlus4F;
    end
end

// Decode Stage
assign op_o = InstrD[6:0];
assign funct3_o = InstrD[14:12];
assign funct7b5_o = InstrD[30];
assign Rs1D_o = InstrD[19:15];
assign Rs2D_o = InstrD[24:20];

// Immediate Generator
always @(*) begin
    case (ImmSrcD_i)
        imm_Itype: ImmExt = {{20{InstrD[31]}}, InstrD[31:20]};
        imm_Stype: ImmExt = {{20{InstrD[31]}}, InstrD[31:25], InstrD[11:7]};
        imm_Btype: ImmExt = {{20{InstrD[31]}}, InstrD[7], InstrD[30:25], InstrD[11:8], 1'b0};
        imm_Jtype: ImmExt = {{12{InstrD[31]}}, InstrD[19:12], InstrD[20], InstrD[30:21], 1'b0};
        imm_Utype: ImmExt = {InstrD[31:12], 12'b0};
        default:   ImmExt = 32'b0;
    endcase
end

// Register File
ucsbece154b_rf rf(
    .clk(clk),
    .a1_i(Rs1D),
    .a2_i(Rs2D),
    .a3_i(RdW_o),
    .rd1_o(RD1),
    .rd2_o(RD2),
    .we3_i(RegWriteW_i),
    .wd3_i(ResultW)
);

// Pipeline Register: Decode -> Execute
always @(posedge clk) begin
    if (FlushE_i) begin
        Rd1D <= 32'b0;
        Rd2D <= 32'b0;
        ImmExtD <= 32'b0;
        Rs1D <= 5'b0;
        Rs2D <= 5'b0;
        RdD <= 5'b0;
        PCPlus4D <= 32'b0;
    end else begin
        Rd1D <= RD1;
        Rd2D <= RD2;
        ImmExtD <= ImmExt;
        Rs1D <= InstrD[19:15];
        Rs2D <= InstrD[24:20];
        RdD <= InstrD[11:7];
        PCPlus4D <= PCPlus4D;
    end
end

// Execute Stage
// Forwarding Muxes
assign SrcAE = ForwardAE_i[1] ? ALUResultM_o :
              ForwardAE_i[0] ? ResultW :
              Rd1D;

assign SrcBE = ALUSrcE_i ? ImmExtD :
              ForwardBE_i[1] ? ALUResultM_o :
              ForwardBE_i[0] ? ResultW :
              Rd2D;

// ALU
ucsbece154b_alu alu(
    .a_i(SrcAE),
    .b_i(SrcBE),
    .alucontrol_i(ALUControlE_i),
    .result_o(ALUResultE),
    .zero_o(ZeroE_o)
);

assign PCTargetE = PCPlus4D + (ImmExtD << 1);

// Pipeline Register: Execute -> Memory
always @(posedge clk) begin
    if (FlushE_i) begin
        ALUResultM_o <= 32'b0;
        WriteDataM_o <= 32'b0;
        RdM_o <= 5'b0;
    end else begin
        ALUResultM_o <= ALUResultE;
        WriteDataM_o <= SrcBE;
        RdM_o <= RdD;
    end
end

// Memory Stage
always @(posedge clk) begin
    ReadDataM <= ReadDataM_i;
end

// Pipeline Register: Memory -> Writeback
always @(posedge clk) begin
    ResultW <= ResultSrcM_i[1] ? PCPlus4M :
              ResultSrcM_i[0] ? ReadDataM :
              ALUResultM_o;
    RdW_o <= RdM_o;
end

// Output assignments
assign PCF_o = PCF;
assign Rs1E_o = Rs1D;
assign Rs2E_o = Rs2D;
assign RdE_o = RdD;

endmodule







