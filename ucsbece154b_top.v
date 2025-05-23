// ucsbece154b_top.v
// ECE 154B, RISC-V pipelined processor 
// All Rights Reserved
// Copyright (c) 2024 UCSB ECE
// Distribution Prohibited


module ucsbece154b_top (
    input clk, reset
    output [31:0] InstD,
    output [31:0] RD1E, RD2E, ExtImmE,
    output [31:0] ResultW
);

wire [31:0] pc, instr, readdata;
wire [31:0] writedata, dataadr;
wire        memwrite;


// processor and memories are instantiated here
ucsbece154b_riscv_pipe riscv (
    .clk(clk), .reset(reset),
    .PCF_o(pc),
    .InstrF_i(instr),
    .MemWriteM_o(memwrite),
    .ALUResultM_o(dataadr), 
    .WriteDataM_o(writedata),
    .ReadDataM_i(readdata)
    .InstD_o(InstD),
    .RD1E_o(RD1E),
    .RD2E_o(RD2E),
    .ImmExtE_o(ImmExtE),
    .ResultW_o(ResultW)
);
ucsbece154_imem imem (
    .a_i(pc), .rd_o(instr)
);
ucsbece154_dmem dmem (
    .clk(clk), .we_i(memwrite),
    .a_i(dataadr), .wd_i(writedata),
    .rd_o(readdata)
);

endmodule
