`resetall
`default_nettype none

/* Instraction Decoder in ID Stage */
module decoder_id (
    input  wire        auipc      ,
    input  wire        lui        ,
    input  wire        branch     ,
    input  wire        jalr       ,
    input  wire        jal        ,
    input  wire        op_imm     ,
    input  wire        op         ,
    input  wire        store      ,
    input  wire  [2:0] fct3       ,
    input  wire  [6:0] fct7       ,
    output wire  [6:0] bru_ctrl   ,
    output wire  [9:0] alu_ctrl   ,
    output wire  [3:0] store_ctrl ,
    output wire  [3:0] load_ctrl
);

    /* Control Signal for ALU */
    assign alu_ctrl[ 0] = ((op && fct7[5]) || ((op || op_imm) && (fct3[2:1]==2'b01))); // is_neg        : sub, slti, sltiu, slt, sltu
    assign alu_ctrl[ 1] = ((op || op_imm) && (fct3==3'b000) || lui || auipc)         ; // is_add_sub    : addi, add, sub, lui, auipc
    assign alu_ctrl[ 2] = ((op || op_imm) && (fct3==3'b011))                         ; // is_unsigned   : sltiu, sltu
    assign alu_ctrl[ 3] = ((op || op_imm) && (fct3[2:1]==2'b01))                     ; // is_cmp        : slti, sltiu, slt, sltu
    assign alu_ctrl[ 4] = ((op || op_imm) && (fct3==3'b101) && fct7[5])              ; // is_arithmetic : srai, sra
    assign alu_ctrl[ 5] = ((op || op_imm) && (fct3==3'b001))                         ; // is_shift_left : slli, sll
    assign alu_ctrl[ 6] = ((op || op_imm) && (fct3==3'b101))                         ; // is_shift_right: srli, srl, srai, sra
    assign alu_ctrl[ 7] = ((op || op_imm) && ({fct3[2],fct3[0]}==2'b10))             ; // is_xor_or     : xori, xor, ori, or
    assign alu_ctrl[ 8] = ((op || op_imm) && (        fct3[2:1]==2'b11))             ; // is_or_and     : ori, or, andi, and
    assign alu_ctrl[ 9] = (jalr || jal)                                              ; // is_jalr_jal   : jalr, jal

    /* Control Signal for BRU */
    assign bru_ctrl[0] = (fct3[2:1]==2'b10)                    ; // is_signed: blt, bge
    assign bru_ctrl[1] = jalr                                  ; // is_jalr  : jalr
    assign bru_ctrl[2] = jal                                   ; // is_jal   : jal
    assign bru_ctrl[3] = (branch && (fct3==3'b000))            ; // is_beq   : beq
    assign bru_ctrl[4] = (branch && (fct3==3'b001))            ; // is_bne   : bne
    assign bru_ctrl[5] = (branch && ({fct3[2],fct3[0]}==2'b10)); // is_blt   : blt, bltu
    assign bru_ctrl[6] = (branch && ({fct3[2],fct3[0]}==2'b11)); // is_bge   : bge, bgeu

    /* Control Signal for Store */
    assign store_ctrl[0] = (fct3[1:0]==2'b00); // sb
    assign store_ctrl[1] = (fct3[1:0]==2'b01); // sh
    assign store_ctrl[2] = (fct3[1:0]==2'b10); // sw
    assign store_ctrl[3] = (fct3[1:0]==2'b11); // sd

    /* Control Signal for Load */
    assign load_ctrl[0] = !fct3[2]          ; // signed
    assign load_ctrl[1] = (fct3[1:0]==2'b00); // lb
    assign load_ctrl[2] = (fct3[1:0]==2'b01); // lh
    assign load_ctrl[3] = (fct3[1:0]==2'b10); // lw

endmodule

`resetall
