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

assign PCSrcE_o = (branch & ZeroE_i) | jump; // PCSrc is set to 1 if branch or jump is taken
assign ImmSrcD_o = controls[10:8]; 
assign branch = controls[3]; 
assign ALUOp = controls[2:1]; 
assign jump = controls[0]; 

always @* begin
    case (op_i)
        instr_jal_op:       controls = 12'b1_011_x_0_10_0_xx_1;
        instr_lui_op:       controls = 12'b1_100_1_0_11_0_xx_0;
        instr_lw_op:        controls = 12'b1_000_1_0_01_0_00_0;       
	    instr_sw_op:        controls = 12'b0_001_1_1_xx_0_00_0;  
	    instr_Rtype_op:     controls = 12'b1_xxx_0_0_00_0_10_0;   
	    instr_beq_op:       controls = 12'b0_010_0_0_xx_1_01_0;   
	    instr_ItypeALU_op:  controls = 12'b1_000_1_0_00_0_10_0;
        default: begin	    
                            controls = 12'bx_xxx_x_x_xx_x_xx_x;       
            `ifdef SIM
                $warning("Unsupported op given: %h", op_i);
            `else
            ;
            `endif
            
        end 
    endcase

    RegWriteW_o = controls[11]; // register write
    ALUSrcE_o = controls[7]; // ALU source
    MemWriteM_o = controls[6]; // memory write
    ResultSrcW_o = controls[5:4]; // result source
end

// Add this after main decoder
always @* begin
    case(ALUOp)
        ALUop_mem: ALUControlE_o = ALUcontrol_add;  // LW/SW
        ALUop_beq: ALUControlE_o = ALUcontrol_sub;  // BEQ
        ALUop_other: begin  // R-type/I-type
            case(funct3_i)
                3'b000: ALUControlE_o = funct7b5_i ? 
                                      ALUcontrol_sub : ALUcontrol_add;
                3'b010: ALUControlE_o = ALUcontrol_slt;
                3'b110: ALUControlE_o = ALUcontrol_or;
                3'b111: ALUControlE_o = ALUcontrol_and;
                default: ALUControlE_o = 3'bxxx;
            endcase
        end
        default: ALUControlE_o = 3'bxxx;
    endcase
end


wire RtypeSub;
assign RtypeSub = funct7b5_i & op_i[5]; // R-type subtract instruction

always @* begin
    case (ALUOp)
        ALUop_mem: ALUControlE_o = ALUcontrol_add;  // LW/SW
        ALUop_beq: ALUControlE_o = ALUcontrol_sub;  // BEQ
        ALUop_other:   // R-type/I-type
            case(funct3_i)
                instr_addsub_funct3:
                    if(RtypeSub)   ALUControlE_o = ALUcontrol_sub; // subtraction else 
                    else           ALUControlE_o = ALUcontrol_add; // addition
                instr_slt_funct3:  ALUControlE_o = ALUcontrol_slt;  // set less than (101)
                instr_or_funct3:   ALUControlE_o = ALUcontrol_or; // or operation (011)
                instr_and_funct3:  ALUControlE_o = ALUcontrol_and;  // and operation (010)
            default: begin
                            ALUControlE_o = 3'bxxx;
                `ifdef SIM
                    $warning("Unsupported funct3 given: %h", funct3_i);
                `else
                ;
                `endif  
            end
            endcase
    default: 
        `ifdef SIM
            $warning("Unsupported ALUop given: %h", ALUOp);
        `else
        ;
        `endif   
    endcase
end

assign FlushD_o = jump;  // Flush decode stage on jumps
assign FlushE_o = jump;  // Flush execute stage on jumps

// Stall signals (simplified example)
assign StallF_o = 1'b0;  // No stalling in this example
assign StallD_o = 1'b0;  // No stalling in this example

// Simple forwarding example
always @* begin
    ForwardAE_o = (Rs1E_i == RdM_i) ? 2'b10 : 
                 (Rs1E_i == RdW_i) ? 2'b01 : 
                 2'b00;
    ForwardBE_o = (Rs2E_i == RdM_i) ? 2'b10 : 
                 (Rs2E_i == RdW_i) ? 2'b01 : 
                 2'b00;
end
endmodule

