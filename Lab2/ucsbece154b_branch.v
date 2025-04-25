// ucsbece154_branch.v
// All Rights Reserved
// Copyright (c) 2024 UCSB ECE
// Distribution Prohibited


module ucsbece154b_branch (
    parameter NUM_BTB_ENTRIES = 32,
    parameter NUM_GHR_BITS    = 5
) (
    input               clk, 
    input               reset_i,
    input        [31:0] pc_i,
    input  [$clog2(NUM_BTB_ENTRIES)-1:0] BTBwriteaddress_i,
    input        [31:0] BTBwritedata_i,   
    output reg   [31:0] BTBtarget_o,           
    input               BTB_we, 
    output reg          BranchTaken_o,
    input         [6:0] op_i, 
    input               PHTincrement_i, 
    input               GHRreset_i,
    input               PHTwe_i,
    input    [NUM_GHR_BITS-1:0]  PHTwriteaddress_i,
    output   [NUM_GHR_BITS-1:0]  PHTreadaddress_o

);

`include "ucsbece154b_defines.vh"

// BTB Storage (direct-mapped)
reg [31:0] BTB_target [0:NUM_BTB_ENTRIES-1];
reg BTB_J [0:NUM_BTB_ENTRIES-1];  // Jump flag
reg BTB_B [0:NUM_BTB_ENTRIES-1];  // Branch flag

// Global History Register (GHR)
reg [NUM_GHR_BITS-1:0] GHR;

// PHT with 2-bit saturating counters
reg [1:0] PHT [0:(1 << NUM_GHR_BITS)-1];

// Indexing for BTB and PHT
wire [$clog2(NUM_BTB_ENTRIES)-1:0] BTB_index = pc_i[6:2]; // PC[6:2] for 32 entries
wire [NUM_GHR_BITS-1:0] PHT_index = pc_i[NUM_GHR_BITS+1:2] ^ GHR;

// Branch detection in fetch
wire is_branch_fetch = (op_i == instr_branch_op);
wire is_jump_fetch = (op_i == instr_jal_op) || (op_i == instr_jalr_op);

// BTB Lookup
always @* begin
    BTBtarget_o = BTB_target[BTB_index];
    // Check BTB validity (J/B flags) and PHT prediction
    BranchTaken_o = (is_jump_fetch && BTB_J[BTB_index]) || 
                    (is_branch_fetch && BTB_B[BTB_index] && (PHT[PHT_index] >= 2'd2));
end

// Update BTB (synchronous write)
always @(posedge clk) begin
    if (reset_i) begin
        for (integer i = 0; i < NUM_BTB_ENTRIES; i = i + 1) begin
            BTB_J[i] <= 1'b0;
            BTB_B[i] <= 1'b0;
        end
    end else if (BTB_we) begin
        BTB_target[BTBwriteaddress_i] <= BTBwritedata_i;
        BTB_J[BTBwriteaddress_i] <= BTB_J_i;
        BTB_B[BTBwriteaddress_i] <= BTB_B_i;
    end
end

// Update GHR (speculative)
always @(posedge clk) begin
    if (reset_i || GHRreset_i) begin
        GHR <= {NUM_GHR_BITS{1'b0}};
    end else if (is_branch_fetch || is_jump_fetch) begin
        GHR <= {GHR[NUM_GHR_BITS-2:0], BranchTaken_o};
    end
end

// Update PHT (synchronous)
always @(posedge clk) begin
    if (reset_i) begin
        for (integer i = 0; i < (1 << NUM_GHR_BITS); i = i + 1)
            PHT[i] <= 2'b01; // Weakly not-taken
    end else if (PHTwe_i) begin
        case (PHT[PHTwriteaddress_i])
            2'b00: PHT[PHTwriteaddress_i] <= PHTincrement_i ? 2'b01 : 2'b00;
            2'b01: PHT[PHTwriteaddress_i] <= PHTincrement_i ? 2'b10 : 2'b00;
            2'b10: PHT[PHTwriteaddress_i] <= PHTincrement_i ? 2'b11 : 2'b01;
            2'b11: PHT[PHTwriteaddress_i] <= PHTincrement_i ? 2'b11 : 2'b10;
        endcase
    end 
end 

always @(posedge clk) begin
    if (reset_i) begin
        for (integer i=0; i<NUM_BTB_ENTRIES; i++) BTB_valid[i] <= 0;
    end
    else if (BTB_we) begin
        BTB[BTBwriteaddress_i] <= BTBwritedata_i;
        BTB_valid[BTBwriteaddress_i] <= 1;
    end
end

assign PHTreadaddress_o = pc_i[NUM_GHR_BITS+1:2] ^ GHR;


endmodule