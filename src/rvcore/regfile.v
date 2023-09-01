`resetall
`default_nettype none

/* Register File */
module regfile #(
    parameter XLEN = 32
) (
    input  wire            clk   ,
    input  wire            en    ,
    input  wire      [4:0] rs1   ,
    input  wire      [4:0] rs2   ,
    output wire [XLEN-1:0] rdata1,
    output wire [XLEN-1:0] rdata2,
    input  wire            we    ,
    input  wire      [4:0] rd    ,
    input  wire [XLEN-1:0] wdata
);

    reg [XLEN-1:0] ram [0:31];
    integer i; initial for (i=0; i<32; i=i+1) ram[i]=32'h00000000;

    assign rdata1 = (rs1==5'd0) ? {XLEN{1'b0}} : ram[rs1];
    assign rdata2 = (rs2==5'd0) ? {XLEN{1'b0}} : ram[rs2];
    always @(posedge clk) begin
        if (en) begin
            if (we) ram[rd] <= wdata;
        end
    end

endmodule

`resetall
