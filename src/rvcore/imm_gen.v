`resetall
`default_nettype none

/* Immediate Value Generator */
module imm_gen #(
    parameter XLEN = 32
) (
    input  wire     [31:0] ir        ,
    input  wire      [4:0] instr_type, // {j, u, b, s, i}
    output wire [XLEN-1:0] imm
);

    wire i, s, b, u, j;
    assign {j, u, b, s, i} = instr_type;

    wire [31:0] imm_i = (i) ? {{20{ir[31]}}, ir[31:20]}                          : 32'h0;
    wire [31:0] imm_s = (s) ? {{20{ir[31]}}, ir[31:25], ir[11:7]}                : 32'h0;
    wire [31:0] imm_b = (b) ? {{20{ir[31]}}, ir[7], ir[30:25], ir[11:8], 1'b0}   : 32'h0;
    wire [31:0] imm_u = (u) ? {ir[31:12], 12'b0}                                 : 32'h0;
    wire [30:0] imm_j = (j) ? {{11{ir[31]}}, ir[19:12], ir[20], ir[30:21], 1'b0} : 32'h0;
    wire [31:0] imm_t = imm_i ^ imm_s ^ imm_b ^ imm_u ^ imm_j;

generate
if (XLEN==32) begin
    assign imm = imm_t;
end
if (XLEN==64) begin
    assign imm = {{32{ir[31]}}, imm_t};
end
endgenerate

endmodule

`resetall
