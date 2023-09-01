`resetall
`default_nettype none

`include "config.vh"

`ifdef VERILATOR
module top (
    input  wire clk  ,
    input  wire rst_n
);
`else
module top;
    reg clk   = 0; always #1 clk <= !clk;
    reg rst_n = 0;
    initial begin
        #10 rst_n = 1;
    end
`endif

    reg [63:0] sim_cycle = 0;
    always @(posedge clk) begin
        sim_cycle <= sim_cycle+1;
    end

`ifdef TIMEOUT
    always @(negedge clk) begin
        if (sim_cycle>`TIMEOUT) begin
            $write("Simulation Time Out...\n");
            $finish;
        end
    end
`endif

`ifdef TRACE_VCD
    initial begin
        $dumpfile(`TRACE_VCD_FILE);
        $dumpvars(0);
    end
`endif

`ifdef TRACE_FST
    initial begin
        $dumpfile(`TRACE_FST_FILE);
        $dumpvars(0);
    end
`endif

    /* DUT: Design Under Test*/
    rvbug rvbug0 (
        .aclk_i   (clk  ),
        .areset_ni(rst_n)
    );

    wire [`XLEN-1:0] pc          = rvbug0.rvcore0.MaWb_pc    ;
    wire [`ILEN-1:0] ir          = rvbug0.rvcore0.MaWb_ir    ;
    wire             valid_instr = rvbug0.rvcore0.valid_instr;

    always @(negedge clk) begin
        if (rvbug0.dmem_wvalid && (rvbug0.dmem_waddr==`TOHOST_ADDR) && (rvbug0.dmem_wdata[17:16]==2'b01)) begin
            $write("%c", rvbug0.dmem_wdata[7:0]);
        end
    end

    reg sim_finish_t1 = 1'b0, sim_finish_t2 = 1'b0, sim_finish = 1'b0;
    always @(posedge clk) begin
        if (rvbug0.dmem_wvalid && (rvbug0.dmem_waddr==`TOHOST_ADDR) && (rvbug0.dmem_wdata[17:16]==2'b10)) begin
            sim_finish_t1 <= 1'b1;
        end
        if (sim_finish_t1) begin
            sim_finish_t2 <= 1'b1;
        end
        if (sim_finish_t2) begin
            sim_finish    <= 1'b1;
        end
    end

    reg [63:0] cycle   = 64'h0; // count of the number of processor  clock cycles
    reg [63:0] instret = 64'h0; // count of the number of instructions
    always @(posedge clk) begin // ((rstate==2'b00) || (wstate==2'b00)) --> BOOT
        if (!rst_n) begin
            cycle   <= 64'h0;
            instret <= 64'h0;
        end else if (!sim_finish) begin
            cycle   <=   cycle+               64'h1;
            instret <= instret+{63'h0, valid_instr};
        end
    end

    always @(negedge clk) begin
        if (sim_finish) begin
            $write("\nSimulation Finish.\n");
            $write("==> simulation clock cycles      :%10d\n"       , sim_cycle+1  ); // Note!!
            $write("==> processor  clock cycles      :%10d\n"       , cycle+1      ); // Note!!
            $write("==> valid instructions executed  :%10d\n"       , instret+1    ); // Note!!
            $write("==> instructions per cycle (IPC) :    %b.%04d\n", instret>=cycle, (instret>=cycle) ? ((instret-cycle)*10000)/(cycle+1) : ((instret+1)*10000)/(cycle+1)); // Note!!
            $finish;
        end
    end

`ifdef TRACE_RF
    integer fd; initial fd = $fopen(`TRACE_RF_FILE, "w");
    reg [63:0] trace_cntr = 1;
    integer i, j;
    always @(negedge clk) begin
        if (rst_n && !sim_finish && valid_instr) begin
            if (`TRACE_BEGIN<=trace_cntr && trace_cntr<=`TRACE_END) begin
                $fwrite(fd, "%08d %08x %08x\n", trace_cntr, pc, ir);
                for (i=0; i<4; i=i+1) for (j=0; j<8; j=j+1) begin
                    $fwrite(fd, "%08x", ((i*8+j==0) ? 0 : (rvbug0.rvcore0.regs0.we && (i*8+j==rvbug0.rvcore0.regs0.rd)) ? rvbug0.rvcore0.regs0.wdata : rvbug0.rvcore0.regs0.ram[i*8+j]));
                    $fwrite(fd, "%s", (j!=7 ? " " : "\n"));
                end
            end
            trace_cntr <= trace_cntr+1;
        end
    end
`endif

endmodule

`resetall
