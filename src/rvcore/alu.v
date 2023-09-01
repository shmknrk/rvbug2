`resetall
`default_nettype none

/* Arithmetic Logic Unit */
module alu #(
    parameter XLEN = 32
) (
    input  wire [XLEN-1:0] in1     , // x[rs1] or pc
    input  wire [XLEN-1:0] in2     , // x[rs2] or imm or pc+4
    input  wire      [9:0] alu_ctrl,
    output wire [XLEN-1:0] out
);

    wire is_neg         = alu_ctrl[ 0];
    wire is_add_sub     = alu_ctrl[ 1];
    wire is_unsigned    = alu_ctrl[ 2];
    wire is_cmp         = alu_ctrl[ 3];
    wire is_arithmetic  = alu_ctrl[ 4];
    wire is_shift_left  = alu_ctrl[ 5];
    wire is_shift_right = alu_ctrl[ 6];
    wire is_xor_or      = alu_ctrl[ 7];
    wire is_or_and      = alu_ctrl[ 8];
    wire is_jalr_jal    = alu_ctrl[ 9];

    wire        [XLEN:0] adder_in1          = {in1, 1'b1};
    wire        [XLEN:0] adder_in2          = {in2, 1'b0} ^ {(XLEN+1){is_neg}};
    wire        [XLEN:0] adder_rslt_t       = adder_in1 + adder_in2; // add, sub
    wire      [XLEN-1:0] adder_rslt         = (is_add_sub) ? adder_rslt_t[XLEN:1] : 0;

    wire                 cmp_rslt_t         = (in1[XLEN-1] ^ in2[XLEN-1]) ? ((is_unsigned) ? in2[XLEN-1] : in1[XLEN-1]) : adder_rslt_t[XLEN];
    wire                 cmp_rslt           = (is_cmp) ? cmp_rslt_t : 0;

    wire      [XLEN-1:0] shift_left_in1     = in1;
    wire signed [XLEN:0] shift_right_in1    = {is_arithmetic & in1[XLEN-1], in1};
    wire           [4:0] shamt              = in2[4:0];
    wire      [XLEN-1:0] shift_left_rslt    = (is_shift_left)  ? shift_left_in1 <<  shamt : 0;
    wire        [XLEN:0] shift_right_rslt_t = shift_right_in1 >>> shamt;
    wire      [XLEN-1:0] shift_right_rslt   = (is_shift_right) ? shift_right_rslt_t[XLEN-1:0] : 0;

    wire      [XLEN-1:0] logic_rslt         = ((is_xor_or) ? in1 ^ in2 : 0) | ((is_or_and) ? in1 & in2 : 0);

    wire      [XLEN-1:0] jump_rslt          = (is_jalr_jal) ? in2 : 0;

    assign out[0]    = cmp_rslt | adder_rslt[0]    | shift_left_rslt[0]    | shift_right_rslt[0]    | logic_rslt[0]    | jump_rslt[0];
    assign out[31:1] =            adder_rslt[31:1] | shift_left_rslt[31:1] | shift_right_rslt[31:1] | logic_rslt[31:1] | jump_rslt[31:1];

endmodule

`resetall
