// ucsbece154b_controller.v
// ECE 154B, RISC-V pipelined processor 
// All Rights Reserved
// Copyright (c) 2024 UCSB ECE
// Distribution Prohibited


module ucsbece154b_controller (
    input                clk, reset,
    input         [6:0]  op_i, 
    input         [2:0]  funct3_i,
    input                funct7b5_i,
    input 	         ZeroE_i,
    input         [4:0]  Rs1D_i,
    input         [4:0]  Rs2D_i,
    input         [4:0]  Rs1E_i,
    input         [4:0]  Rs2E_i,
    input         [4:0]  RdE_i,
    input         [4:0]  RdM_i,
    input         [4:0]  RdW_i,
    output wire		 StallF_o,  
    output wire          StallD_o,
    output wire          FlushD_o,
    output wire    [2:0] ImmSrcD_o,
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
reg [11:0] controls;
wire [1:0] ALUOp;
wire lwStall;

assign PCSrcE_o = (ZeroE_i & branche) | jumpe; //assign PCSrc control signal based on diagram

 assign {RegWriteD,	
	ImmSrcD_o,
    ALUSrcD,
    MemWriteD,
    ResultSrcD,
	branchd, 
	ALUOp,
	jumpd} = controls;

 always @ * begin
   case (op_i)
	instr_lw_op:        controls = 12'b1_000_1_0_01_0_00_0;       
	instr_sw_op:        controls = 12'b0_001_1_1_00_0_00_0; 
	instr_Rtype_op:     controls = 12'b1_xxx_0_0_00_0_10_0;  
	instr_beq_op:       controls = 12'b0_010_0_0_00_1_01_0;  
	instr_ItypeALU_op:  controls = 12'b1_000_1_0_00_0_10_0; 
	instr_jal_op:       controls = 12'b1_011_x_0_10_0_xx_1;  //should memwrite be x or 0
    instr_lui_op:       controls = 12'b1_100_x_0_11_0_xx_0;   // note changed ALUOp and MemWrite
	default: 	    controls = 12'b0; 
   endcase
 end

 wire RtypeSub;

 assign RtypeSub = funct7b5_i & op_i[5];

 always @ * begin
 case(ALUOp)
   ALUop_mem:                 ALUControlD = ALUcontrol_add;
   ALUop_beq:                 ALUControlD = ALUcontrol_sub;
   ALUop_other: 
       case(funct3_i)
           instr_addsub_funct3: 
                if(RtypeSub) ALUControlD = ALUcontrol_sub;
                else         ALUControlD = ALUcontrol_add;  
           instr_slt_funct3:  ALUControlD = ALUcontrol_slt;  
           instr_or_funct3:   ALUControlD = ALUcontrol_or;  
           instr_and_funct3:  ALUControlD = ALUcontrol_and;  
           default:           ALUControlD = 3'bxxx;
       endcase
   default: 
      `ifdef SIM
          $warning("Unsupported ALUop given: %h", ALUOp);
      `else
          ;
      `endif   
 endcase
end

wire RegWriteD; 
reg RegWriteE, RegWriteM;
wire[1:0] ResultSrcD; 
reg[1:0] ResultSrcE;
wire MemWriteD; 
reg MemWriteE;
wire jumpd, branchd; 
reg jumpe, branche;
reg[2:0] ALUControlD;
wire ALUSrcD;

always @ (posedge reset, posedge clk) begin
    if (reset) begin
        RegWriteW_o <= 1'b0;
        RegWriteE <= 1'b0;
        RegWriteM <= 1'b0;

        ResultSrcE <= 2'b00;
        ResultSrcM_o <= 2'b0;
        ResultSrcW_o <= 2'b0;

        MemWriteE <= 1'b0;
        MemWriteM_o <= 1'b0;

        jumpe <= 1'b0;
        branche <= 1'b0;

        ALUControlE_o <= 3'b0;
        ALUControlD <= 3'b0;
        ALUSrcE_o <= 1'b0;
        controls <= 12'b0;

        ForwardAE_o <= forward_ex;
        ForwardBE_o <= forward_ex;

    end
    else begin

        // D/E stage
        if (FlushE_o == 1) begin
            RegWriteE <= 1'b0;
            MemWriteE <= 1'b0;
            ResultSrcE <= 2'b0;
            ALUControlE_o <= 3'b0;
            jumpe <= 1'b0;
            branche <= 1'b0;
            ForwardAE_o <= forward_ex;
            ForwardBE_o <= forward_ex;
        end
        else begin
            RegWriteE <= RegWriteD;
            ResultSrcE <= ResultSrcD;
            MemWriteE <= MemWriteD;
            jumpe <= jumpd;
            branche <= branchd;
            ALUControlE_o <= ALUControlD;
            ALUSrcE_o <= ALUSrcD;

            //forwarding
            ForwardAE_o <= forward_ex;
            ForwardBE_o <= forward_ex;

        
            // Rs1 (src a)
            if (Rs1D_i !== 0 && RegWriteE && (Rs1D_i === RdE_i))
                ForwardAE_o <= forward_mem;
            else if (Rs1D_i !== 0 && RegWriteM && (Rs1D_i === RdM_i))
                ForwardAE_o <= forward_wb;
            
            // Rs2 (src b)
            if (Rs1D_i !== 0 && RegWriteE && (Rs2D_i === RdE_i))
                ForwardBE_o <= forward_mem;
            else if (Rs1D_i !== 0 && RegWriteM && (Rs2D_i === RdM_i))
                ForwardBE_o <= forward_wb;
        
        
        end


        // E/M stage 
        RegWriteM <= RegWriteE;
        ResultSrcM_o <= ResultSrcE;
        MemWriteM_o <= MemWriteE;

        // M/W Stage
        RegWriteW_o <= RegWriteM;
        ResultSrcW_o <= ResultSrcM_o;
    end  

end

    // check for load hazard
    assign lwStall  = (ResultSrcE === MuxResult_mem) && ((Rs1D_i === RdE_i) || (Rs2D_i === RdE_i));
    assign StallF_o = lwStall;
    assign StallD_o = lwStall;
    assign FlushE_o = lwStall || (PCSrcE_o === MuxPC_PCTarget);
    assign FlushD_o = (PCSrcE_o === MuxPC_PCTarget);
    


 

endmodule

