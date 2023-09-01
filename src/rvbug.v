`resetall
`default_nettype none

`include "config.vh"

module rvbug (
    input  wire aclk_i   ,
    input  wire areset_ni
);

    /* Processor */
    localparam RESET_VECTOR  = `RESET_VECTOR  ;
    localparam ILEN          = `ILEN          ;
    localparam IBYTES        = (ILEN/8)       ;
    localparam XLEN          = `XLEN          ;
    localparam XBYTES        = (XLEN/8)       ;
    /* Memory */
    localparam MEMSIZE       = `MEMSIZE       ;
    localparam TOHOST_ADDR   = `TOHOST_ADDR   ;

    /* Clock and Reset Siganls */
    wire aclk    ;
    wire areset_n;
`ifdef NO_IP
    assign aclk = aclk_i;
    reg r_areset_n1 = 1'b0, r_areset_n2 = 1'b0;
    always @(posedge aclk) begin
        r_areset_n1 <= areset_ni  ;
        r_areset_n2 <= r_areset_n1;
    end
    assign areset_n = r_areset_n2;
`else
    wire locked;
    clk_wiz_0 clk_wiz_0 (
        .clk_out1(aclk      ),
        .reset   (!areset_ni),
        .locked  (locked    ),
        .clk_in1 (aclk_i    )
    );
    reg r_areset_n1 = 1'b0, r_areset_n2 = 1'b0;
    always @(posedge aclk) begin
        r_areset_n1 <= (areset_ni && locked);
        r_areset_n2 <= r_areset_n1;
    end
    assign areset_n = r_areset_n2;
`endif

    /* Instruction/Data Memory */
    localparam RAM_ADDR_WIDTH = $clog2(MEMSIZE);

    wire   [XLEN-1:0] imem_raddr ;
    wire   [XLEN-1:0] imem_rdata ;
    wire              dmem_wvalid;
    wire   [XLEN-1:0] dmem_addr  ;
    wire   [XLEN-1:0] dmem_waddr ;
    wire [XBYTES-1:0] dmem_wstrb ;
    wire   [XLEN-1:0] dmem_wdata ;
    wire   [XLEN-1:0] dmem_raddr ;
    wire   [XLEN-1:0] dmem_rdata ;

    assign dmem_waddr = dmem_addr;
    assign dmem_raddr = dmem_addr;

    ram #(
        .ADDR_WIDTH(RAM_ADDR_WIDTH),
        .DATA_WIDTH(XLEN          )
    ) imem0 (
        .aclk_i  (aclk                          ),
        .wvalid_i(1'b0                          ),
        .waddr_i ({RAM_ADDR_WIDTH{1'b0}}        ),
        .wstrb_i ({XBYTES{1'b0}}                ),
        .wdata_i ({XLEN{1'b0}}                  ),
        .raddr_i (imem_raddr[RAM_ADDR_WIDTH-1:0]),
        .rdata_o (imem_rdata                    )
    );

    ram #(
        .ADDR_WIDTH(RAM_ADDR_WIDTH),
        .DATA_WIDTH(XLEN          )
    ) dmem0 (
        .aclk_i  (aclk                          ),
        .wvalid_i(dmem_wvalid                   ),
        .waddr_i (dmem_waddr[RAM_ADDR_WIDTH-1:0]),
        .wstrb_i (dmem_wstrb                    ),
        .wdata_i (dmem_wdata                    ),
        .raddr_i (dmem_raddr[RAM_ADDR_WIDTH-1:0]),
        .rdata_o (dmem_rdata                    )
    );

    rvcore #(
        .RESET_VECTOR(RESET_VECTOR),
        .ILEN        (ILEN        ),
        .XLEN        (XLEN        )
    ) rvcore0 (
        .clk_i        (aclk       ),
        .rst_ni       (areset_n   ),
        .stall_i      (1'b0       ),
        .imem_raddr_o (imem_raddr ),
        .imem_rdata_i (imem_rdata ),
        .dmem_addr_o  (dmem_addr  ),
        .dmem_wvalid_o(dmem_wvalid),
        .dmem_wdata_o (dmem_wdata ),
        .dmem_wstrb_o (dmem_wstrb ),
        .dmem_rdata_i (dmem_rdata )
    );

endmodule

`resetall
