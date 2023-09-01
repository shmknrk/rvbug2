`resetall
`default_nettype none

/* Instraction Decoder in IF Stage */
module decoder_if (
    input  wire [31:0] ir        ,
    output wire        auipc     ,
    output wire        lui       ,
    output wire        branch    ,
    output wire        jalr      ,
    output wire        jal       ,
    output wire        op_imm    ,
    output wire        op        ,
    output wire        load      ,
    output wire        store     ,
    output wire  [4:0] instr_type, // = {j, u, b, s, i}
    output wire        rf_we     ,
    output wire  [4:0] rd        ,
    output wire  [4:0] rs1       ,
    output wire  [4:0] rs2
);

    wire [4:0] opcode     = ir[6:2];
    assign     auipc      = (opcode==5'b00101);
    assign     lui        = (opcode==5'b01101);
    assign     branch     = (opcode==5'b11000);
    assign     jalr       = (opcode==5'b11001);
    assign     jal        = (opcode==5'b11011);
    assign     op_imm     = (opcode==5'b00100);
    assign     op         = (opcode==5'b01100);
    assign     load       = (opcode==5'b00000);
    assign     store      = (opcode==5'b11000);
    wire       i          = (load || op_imm || jalr);
    wire       s          = store;
    wire       b          = branch;
    wire       u          = ({opcode[4],opcode[2:0]}==4'b0101); // auipc, lui
    wire       j          = jal;
    assign     instr_type = {j, u, b, s, i};
    assign     rd         = (     s || b) ? 5'd0 : ir[11: 7];
    assign     rs1        = (     u || j) ? 5'd0 : ir[19:15];
    assign     rs2        = (i || u || j) ? 5'd0 : ir[24:20];
    assign     rf_we      = |rd; // (rd!=5'd0);

endmodule

`resetall
