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


//new wires

//Fetch stage
wire [31:0] PcF, PCPlus4F;

//Decode Stage
reg [31:0] InstrD, PcD, PCPlus4D;
wire [31:0] Rd2D, ImmExtD, Rd1D;
wire [4:0] RdD;

//Execute Stage
reg [31:0] Rd1E, Rd2E, PcE, PCPlus4E, ImmExtE;
wire [31:0] SrcAE, SrcBE, WriteDataE, PcTargetE, AluResultE;

//Memory Stage
reg [31:0] PCPlus4M, ImmExtM;
wire [31:0] FwdSrcM; //ImmExtM is simply for pipeline purposes to get it to WB for lui, can i skip the pieplining
//FwdSrcM is for the mux that chooses

//Writeback Stage
reg [31:0] AluResultW, ReadDataW, PCPlus4W, ImmExtW;
wire [31:0] ResultW;


//Imem already declared

//rg in decode
ucsbece154b_rf rf (
    .clk(!clk),
    .a1_i(InstrD[19:15]), .a2_i(InstrD[24:20]), .a3_i(RdW_o),
    .rd1_o(Rd1D), .rd2_o(Rd2D),
    .we3_i(RegWriteW_i), .wd3_i(ResultW)
);

//alu in execute
ucsbece154b_alu alu (
    .a_i(SrcAE), .b_i(SrcBE),
    .alucontrol_i(ALUControlE_i),
    .result_o(AluResultE),
    .zero_o(ZeroE_o)
);

//Dmem already declared

//Fetch Stage Wiring

//PCMUX
assign PcF =  (PCSrcE_i == MuxPC_PCPlus4) ? PCPlus4F : PcTargetE;;
//adder
assign PCPlus4F = PCF_o + 4;

//Decode Stage

assign op_o       = InstrD[6:0];
assign funct3_o   = InstrD[14:12];
assign funct7b5_o = InstrD[30];

assign Rs1D_o = InstrD[19:15];
assign Rs2D_o = InstrD[24:20];
assign RdD = InstrD[11:7];

//always @ * begin
assign ImmExtD = 
    ImmSrcD_i === imm_Itype ? {{20{InstrD[31]}}, InstrD[31:20]} :
    ImmSrcD_i === imm_Stype ? {{20{InstrD[31]}}, InstrD[31:25], InstrD[11:7]} :
    ImmSrcD_i === imm_Btype ? {{20{InstrD[31]}}, InstrD[7], InstrD[30:25], InstrD[11:8], 1'b0} :
    ImmSrcD_i === imm_Jtype ? {{12{InstrD[31]}}, InstrD[19:12], InstrD[20], InstrD[30:21], 1'b0} :
    ImmSrcD_i === imm_Utype ? {InstrD[31:12], 12'b0} :
    32'bx
;
/*
   case(ImmSrcD_i)
      imm_Itype: ImmExtD = {{20{InstrD[31]}},InstrD[31:20]};
      imm_Stype: ImmExtD = {{20{InstrD[31]}},InstrD[31:25],InstrD[11:7]};
      imm_Btype: ImmExtD = {{20{InstrD[31]}},InstrD[7],InstrD[30:25], InstrD[11:8],1'b0};
      imm_Jtype: ImmExtD = {{12{InstrD[31]}},InstrD[19:12],InstrD[20],InstrD[30:21],1'b0};
      imm_Utype: ImmExtD = {InstrD[31:12],12'b0};
      default:   ImmExtD = 32'bx; 
//            `ifdef SIM
//            $warning("Unsupported ImmSrc given: %h", ImmSrc_i);
//            `else
//            ;
//            `endif
   endcase*/
//end

//Execute Stage
//do we have to do this at each stage?

//SrcAE mux
//always @ * begin
assign SrcAE = 
    ForwardAE_i === forward_ex  ? Rd1E :
    ForwardAE_i === forward_wb  ? ResultW :
    ForwardAE_i === forward_mem ? FwdSrcM :
    32'bx
;
	
    /*case (ForwardAE_i)
        forward_ex: SrcAE = Rd1E;
        forward_wb: SrcAE = ResultW;
	forward_mem: SrcAE = FwdSrcM;
        default: 
//          `ifdef SIM
  //          $warning("Unsupported ResultSrc given: %h", ResultSrc_i);
  //          `else
  //          ;
  //          `endif*/
//end


//WriteData mux

//always @ * begin
assign WriteDataE = 
    ForwardBE_i === forward_ex  ? Rd2E :
    ForwardBE_i === forward_wb  ? ResultW :
    ForwardBE_i === forward_mem ? FwdSrcM :
    32'bx
;
/*
    case (ForwardBE_i)
        forward_ex:  WriteDataE= Rd2E;
        forward_wb: WriteDataE = ResultW;
	forward_mem: WriteDataE = FwdSrcM;
        default: 
//          `ifdef SIM
  //          $warning("Unsupported ResultSrc given: %h", ResultSrc_i);
  //          `else
  //          ;
  //          `endif

  //   end
    endcase*/
//end

//SrcBE mux (Depending on control signal ALUSrcE_i choose WD or Imm, pipleine it)

assign SrcBE = (ALUSrcE_i === SrcB_reg) ? WriteDataE : ImmExtE;

//adder

assign PcTargetE = PcE + ImmExtE; // I dedclare PCtargetE here but I use it in the decode stage does it matter

//Memory

//This is the mux for forwarding lui,

//--------------------------------------------------------
//CHANGED FORWARD_mem to FwdSrcM because it is the result of the MUX
//-------------------------------------------------------------

/*always @* begin
    case(ResultSrcM_i)
	00: FwdSrcM = ALUResultM_o;
	MuxResult_imm: FwdSrcM = ImmExtM;
	end
    endcase
end*/

assign FwdSrcM = (ResultSrcM_i === MuxResult_imm) ? ImmExtM : ALUResultM_o;

//Write back 



assign ResultW = 
    ResultSrcW_i === MuxResult_aluout  ? AluResultW :
    ResultSrcW_i === MuxResult_mem     ? ReadDataW :
    ResultSrcW_i === MuxResult_PCPlus4 ? PCPlus4W:
    ResultSrcW_i === MuxResult_imm     ? ImmExtW:
    32'bx
;
/*
    case (ResultSrcW_i)
        MuxResult_aluout: ResultW = AluResultW;
        MuxResult_mem: ResultW = ReadDataW;
	MuxResult_PCPlus4: ResultW = PCPlus4W;
	MuxResult_imm: ResultW = ImmExtW; // this is to implement lui add this to the wires
        default: 
//          `ifdef SIM
  //          $warning("Unsupported ResultSrc given: %h", ResultSrc_i);
  //          `else
  //          ;
  //          `endif

  //   end
    endcase*/



//how would i go about pipelining the wires

//HAZARD UNIT remember to pipeline ImmExtW to ImmExtM

always @ (posedge reset, posedge clk) begin
    if (reset)begin
	PCF_o <= pc_start;
	InstrD <= 32'b0;
	PcD <= 32'b0;
	PCPlus4D <= 32'b0;

	Rd1E <= 32'b0;
	Rd2E <= 32'b0;
    Rs1E_o <= 5'b0;
    Rs2E_o <= 5'b0;
    RdE_o <= 5'b0;
 	PcE <= 32'b0;
	PCPlus4E <= 32'b0;
	ImmExtE <= 32'b0;

	PCPlus4M <= 32'b0;
	ImmExtM <= 32'b0;
    RdM_o <= 5'b0;
    RdW_o <= 5'b0;
	AluResultW <= 32'b0;
    ALUResultM_o <= 32'b0;
	ReadDataW <= 32'b0;
	PCPlus4W <= 32'b0;
	ImmExtW <= 32'b0;
    WriteDataM_o <= 32'b0;

    end
	//if flush at decode do i need to reset the registers at fetch or is
	// that handled by the incriment of the piepline, if flushD is on
	// does that mean flush D is on too, actually no registers in F
    else begin
      if(FlushD_i) begin
	    InstrD <= 32'b0;
	    PcD <= 32'b0;
	    PCPlus4D <= 32'b0;
      end
      else if(!StallD_i) begin
      	InstrD <= InstrF_i;
	    PcD <= PCF_o;
	    PCPlus4D <= PCPlus4F;
      end
      if(FlushE_i) begin
	    Rd1E <= 32'b0;
	    Rd2E <= 32'b0;
        Rs1E_o <= 5'b0;
        Rs2E_o <= 5'b0;
        RdE_o <= 5'b0;
 	    PcE <= 32'b0;
	    PCPlus4E <= 32'b0;
	    ImmExtE <= 32'b0;
      end
      else begin
        Rd1E <= Rd1D;
	    Rd2E <= Rd2D;
	    PcE <= PcD;
	    Rs1E_o <= Rs1D_o;
	    Rs2E_o <= Rs2D_o;
	    RdE_o <= RdD;
	    ImmExtE <= ImmExtD;
	    PCPlus4E <= PCPlus4D;
      
      end 
	
        if(!StallF_i)begin
        PCF_o  <= PcF;
        end



	ALUResultM_o <= AluResultE;
	WriteDataM_o <= WriteDataE;
	RdM_o <= RdE_o;
	PCPlus4M <= PCPlus4E;
	ImmExtM <= ImmExtE;
	
	ReadDataW <= ReadDataM_i;
	PCPlus4W <= PCPlus4M;
	ImmExtW <= ImmExtM;
	RdW_o <= RdM_o;
    AluResultW <= ALUResultM_o;


   end
	
end


endmodule
