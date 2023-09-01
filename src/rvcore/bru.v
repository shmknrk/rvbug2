`resetall
`default_nettype none

/* Branch Resolution Unit */
module bru #(
    parameter XLEN = 32
) (
    input  wire [XLEN-1:0] in1     , // x[rs1]
    input  wire [XLEN-1:0] in2     , // x[rs2] or imm
    input  wire [XLEN-1:0] pc      ,
    input  wire [XLEN-1:0] imm     ,
    input  wire      [6:0] bru_ctrl,
    output wire            tkn     ,
    output wire [XLEN-1:0] tkn_pc
);

    wire is_signed = bru_ctrl[0];
    wire is_jalr   = bru_ctrl[1];
    wire is_jal    = bru_ctrl[2];
    wire is_beq    = bru_ctrl[3];
    wire is_bne    = bru_ctrl[4];
    wire is_blt    = bru_ctrl[5];
    wire is_bge    = bru_ctrl[6];

    wire signed [XLEN:0] sin1 = {is_signed && in1[XLEN-1], in1};
    wire signed [XLEN:0] sin2 = {is_signed && in2[XLEN-1], in2};

    wire beq_bne_tkn = (in1==in2)  ? is_beq : is_bne;
    wire blt_bge_tkn = (sin1<sin2) ? is_blt : is_bge;

    assign tkn    = (is_jalr || is_jal || beq_bne_tkn || blt_bge_tkn);
    assign tkn_pc = (is_jalr) ? in1+imm : pc+imm;

endmodule

`resetall
