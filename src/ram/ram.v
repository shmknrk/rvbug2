`resetall
`default_nettype none

module ram #(
    parameter ADDR_WIDTH = 16            ,
    parameter DATA_WIDTH = 32            ,
    parameter STRB_WIDTH = (DATA_WIDTH/8)
) (
    input  wire                  aclk_i  ,
    input  wire                  wvalid_i,
    input  wire [ADDR_WIDTH-1:0] waddr_i ,
    input  wire [STRB_WIDTH-1:0] wstrb_i ,
    input  wire [DATA_WIDTH-1:0] wdata_i ,
    input  wire [ADDR_WIDTH-1:0] raddr_i ,
    output reg  [DATA_WIDTH-1:0] rdata_o
);

    localparam OFFSET_WIDTH     = $clog2(STRB_WIDTH)     ;
    localparam VALID_ADDR_WIDTH = ADDR_WIDTH-OFFSET_WIDTH;
    integer i;

    reg [DATA_WIDTH-1:0] ram [0:2**VALID_ADDR_WIDTH-1];
    initial begin
        $readmemh(`MEMFILE, ram);
    end

    wire [VALID_ADDR_WIDTH-1:0] valid_waddr = waddr_i[ADDR_WIDTH-1:OFFSET_WIDTH];
    wire [VALID_ADDR_WIDTH-1:0] valid_raddr = raddr_i[ADDR_WIDTH-1:OFFSET_WIDTH];

    always @(posedge aclk_i) begin
        rdata_o <= ram[valid_raddr];
        if (wvalid_i) begin
            for (i=0; i<STRB_WIDTH; i=i+1) begin
                if (wstrb_i[i]) ram[valid_waddr][8*i+:8] <= wdata_i[8*i+:8];
            end
        end
    end

endmodule

`resetall
