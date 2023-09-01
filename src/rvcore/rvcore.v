`resetall
`default_nettype none

module rvcore #(
    parameter RESET_VECTOR = 32'h00000000,
    parameter ILEN         = 32          ,
    parameter XLEN         = 32          ,
    parameter XBYTES       = (XLEN/8)
) (
    input  wire              clk_i        ,
    input  wire              rst_ni       ,
    input  wire              stall_i      ,
    output wire   [XLEN-1:0] imem_raddr_o ,
    input  wire   [ILEN-1:0] imem_rdata_i ,
    output wire   [XLEN-1:0] dmem_addr_o  ,
    output wire              dmem_wvalid_o,
    output wire   [XLEN-1:0] dmem_wdata_o ,
    output wire [XBYTES-1:0] dmem_wstrb_o ,
    input  wire   [XLEN-1:0] dmem_rdata_i
);

    /***** Pipeline Registers *****/
    reg           [XLEN-1:0] r_pc                ;

    /* IF/ID */
    reg                      IfId_v              ;
    reg           [XLEN-1:0] IfId_pc             ;
    reg           [ILEN-1:0] IfId_ir             ;
    reg                      IfId_load_use       ;
    reg                      IfId_auipc          ;
    reg                      IfId_lui            ;
    reg                      IfId_branch         ;
    reg                      IfId_jalr           ;
    reg                      IfId_jal            ;
    reg                      IfId_op_imm         ;
    reg                      IfId_op             ;
    reg                      IfId_load           ;
    reg                      IfId_store          ;
    reg                [4:0] IfId_instr_type     ;
    reg                      IfId_rf_we          ;
    reg                [4:0] IfId_rd             ;
    reg                [4:0] IfId_rs1            ;
    reg                [4:0] IfId_rs2            ;

    /* ID/EX */
    reg                      IdEx_v              ;
    reg           [XLEN-1:0] IdEx_pc             ;
    reg           [ILEN-1:0] IdEx_ir             ;
    reg                      IdEx_load           ;
    reg                      IdEx_store          ;
    reg                [6:0] IdEx_bru_ctrl       ;
    reg                [9:0] IdEx_alu_ctrl       ;
    reg                [3:0] IdEx_store_ctrl     ;
    reg                [3:0] IdEx_load_ctrl      ;
    reg                      IdEx_rf_we          ;
    reg                [4:0] IdEx_rd             ;
    reg                      IdEx_rs1_fwd_from_Ma;
    reg                      IdEx_rs2_fwd_from_Ma;
    reg                      IdEx_rs1_fwd_from_Wb;
    reg                      IdEx_rs2_fwd_from_Wb;
    reg           [XLEN-1:0] IdEx_xrs1           ;
    reg           [XLEN-1:0] IdEx_xrs2           ;
    reg           [XLEN-1:0] IdEx_imm            ;

    /* EX/MA */
    reg                      ExMa_v              ;
    reg           [XLEN-1:0] ExMa_pc             ;
    reg           [ILEN-1:0] ExMa_ir             ;
    reg                      ExMa_tkn            ;
    reg           [XLEN-1:0] ExMa_tkn_pc         ;
    reg                      ExMa_load           ;
    reg                [3:0] ExMa_load_ctrl      ;
    reg [$clog2(XBYTES)-1:0] ExMa_dmem_offset    ;
    reg                      ExMa_rf_we          ;
    reg                [4:0] ExMa_rd             ;
    reg           [XLEN-1:0] ExMa_rslt           ;

    /* MA/WB */
    reg                      MaWb_v              ;
    reg           [XLEN-1:0] MaWb_pc             ;
    reg           [ILEN-1:0] MaWb_ir             ;
    reg                      MaWb_rf_we          ;
    reg                [4:0] MaWb_rd             ;
    reg           [XLEN-1:0] MaWb_rslt           ;

    /* Valid */
    wire            Ma_bp_miss = (Ma_v && ExMa_tkn);
    wire [XLEN-1:0] Ma_true_pc = ExMa_tkn_pc;

    wire If_v = (!rst_ni || Ma_bp_miss                 ) ? 1'b0 : (IfId_load_use) ? IfId_v :   1'b1;
    wire Id_v = (!rst_ni || Ma_bp_miss || IfId_load_use) ? 1'b0 :                            IfId_v;
    wire Ex_v = (!rst_ni || Ma_bp_miss                 ) ? 1'b0 :                            IdEx_v;
    wire Ma_v = (!rst_ni                               ) ? 1'b0 :                            ExMa_v;
    wire Wb_v = (!rst_ni                               ) ? 1'b0 :                            MaWb_v;

    /***** IF Stage *****/
    wire [XLEN-1:0] npc = (!rst_ni) ? RESET_VECTOR : (stall_i) ? r_pc : (Ma_bp_miss) ? Ma_true_pc : (IfId_load_use) ? r_pc : r_pc+4;
    always @(posedge clk_i) r_pc <= npc;
    assign imem_raddr_o = npc;

    wire [ILEN-1:0] If_ir = imem_rdata_i;

    /* Instruction Decoder in IF Stage */
    wire        If_auipc, If_lui, If_branch, If_jalr, If_jal, If_op_imm, If_op, If_load, If_store;
    wire  [4:0] If_instr_type;
    wire        If_rf_we;
    wire  [4:0] If_rd, If_rs1, If_rs2;
    decoder_if decoder_if0 (
        .ir        (If_ir        ),
        .auipc     (If_auipc     ),
        .lui       (If_lui       ),
        .branch    (If_branch    ),
        .jalr      (If_jalr      ),
        .jal       (If_jal       ),
        .op_imm    (If_op_imm    ),
        .op        (If_op        ),
        .load      (If_load      ),
        .store     (If_store     ),
        .instr_type(If_instr_type), // = {j, u, b, s, i}
        .rf_we     (If_rf_we     ),
        .rd        (If_rd        ),
        .rs1       (If_rs1       ),
        .rs2       (If_rs2       )
    );

    wire If_load_use = (Id_v && IfId_rf_we && ((If_rs1==IfId_rd) || (If_rs2==IfId_rd)) && IfId_load && !IfId_load_use);

    always @(posedge clk_i) begin
        if (!rst_ni) begin
            IfId_v          <= 0;
            IfId_load_use   <= 0;
            IfId_pc         <= 0;
            IfId_ir         <= 0;
            IfId_auipc      <= 0;
            IfId_lui        <= 0;
            IfId_branch     <= 0;
            IfId_jalr       <= 0;
            IfId_jal        <= 0;
            IfId_op_imm     <= 0;
            IfId_op         <= 0;
            IfId_load       <= 0;
            IfId_store      <= 0;
            IfId_instr_type <= 0;
            IfId_rf_we      <= 0;
            IfId_rd         <= 0;
            IfId_rs1        <= 0;
            IfId_rs2        <= 0;
        end else if (!stall_i) begin
            IfId_v          <= If_v          ;
            IfId_load_use   <= If_load_use   ;
            if (!IfId_load_use) begin
                IfId_pc         <= r_pc          ;
                IfId_ir         <= If_ir         ;
                IfId_auipc      <= If_auipc      ;
                IfId_lui        <= If_lui        ;
                IfId_branch     <= If_branch     ;
                IfId_jalr       <= If_jalr       ;
                IfId_jal        <= If_jal        ;
                IfId_op_imm     <= If_op_imm     ;
                IfId_op         <= If_op         ;
                IfId_load       <= If_load       ;
                IfId_store      <= If_store      ;
                IfId_instr_type <= If_instr_type ;
                IfId_rf_we      <= If_rf_we      ;
                IfId_rd         <= If_rd         ;
                IfId_rs1        <= If_rs1        ;
                IfId_rs2        <= If_rs2        ;
            end
        end
    end

    /***** ID Stage *****/
    wire  [2:0] Id_fct3 = IfId_ir[14:12];
    wire  [6:0] Id_fct7 = IfId_ir[31:25];

    wire  [6:0] Id_bru_ctrl  ;
    wire  [9:0] Id_alu_ctrl  ;
    wire  [3:0] Id_store_ctrl;
    wire  [3:0] Id_load_ctrl ;
    decoder_id decoder_id0(
        .auipc     (IfId_auipc     ),
        .lui       (IfId_lui       ),
        .branch    (IfId_branch    ),
        .jalr      (IfId_jalr      ),
        .jal       (IfId_jal       ),
        .op_imm    (IfId_op_imm    ),
        .op        (IfId_op        ),
        .store     (IfId_store     ),
        .fct3      (  Id_fct3      ),
        .fct7      (  Id_fct7      ),
        .bru_ctrl  (  Id_bru_ctrl  ),
        .alu_ctrl  (  Id_alu_ctrl  ),
        .store_ctrl(  Id_store_ctrl),
        .load_ctrl (  Id_load_ctrl )
    );

    /* Register File */
    wire [XLEN-1:0] Id_xrs1, Id_xrs2;
    wire Wb_rf_we = (Wb_v && MaWb_rf_we);
    regfile #(
        .XLEN(XLEN)
    ) regs0 (
        .clk   (clk_i     ),
        .en    (!stall_i  ),
        .rs1   (IfId_rs1  ),
        .rs2   (IfId_rs2  ),
        .rdata1(  Id_xrs1 ),
        .rdata2(  Id_xrs2 ),
        .we    (  Wb_rf_we),
        .rd    (MaWb_rd   ),
        .wdata (MaWb_rslt )
    );

    /* Immediate Value Generator */
    wire [XLEN-1:0] Id_imm;
    imm_gen imm_gen0 (
        .ir        (IfId_ir        ),
        .instr_type(IfId_instr_type), // {j, u, b, s, i}
        .imm       (  Id_imm       )
    );

    /* Data Forwarding */
    wire Id_rs1_fwd_from_Ma = (Ex_v && IdEx_rf_we && (IfId_rs1==IdEx_rd));
    wire Id_rs2_fwd_from_Ma = (Ex_v && IdEx_rf_we && (IfId_rs2==IdEx_rd));
    wire Id_rs1_fwd_from_Wb = (Ma_v && ExMa_rf_we && (IfId_rs1==ExMa_rd));
    wire Id_rs2_fwd_from_Wb = (Ma_v && ExMa_rf_we && (IfId_rs2==ExMa_rd));

    wire Id_i_type = IfId_instr_type[0];
    wire Id_u_type = IfId_instr_type[3];
    wire [XLEN-1:0] Id_xrs1_t =                                  (IfId_lui) ? 0 : (IfId_auipc) ? IfId_pc : (Wb_v && MaWb_rf_we && (IfId_rs1==MaWb_rd)) ? MaWb_rslt : Id_xrs1;
    wire [XLEN-1:0] Id_xrs2_t = (IfId_jalr || IfId_jal) ? IfId_pc+4 : (Id_i_type || Id_u_type) ?  Id_imm : (Wb_v && MaWb_rf_we && (IfId_rs2==MaWb_rd)) ? MaWb_rslt : Id_xrs2;

    always @(posedge clk_i) begin
        if (!rst_ni) begin
            IdEx_v               <= 0;
            IdEx_pc              <= 0;
            IdEx_ir              <= 0;
            IdEx_load            <= 0;
            IdEx_store           <= 0;
            IdEx_bru_ctrl        <= 0;
            IdEx_alu_ctrl        <= 0;
            IdEx_store_ctrl      <= 0;
            IdEx_load_ctrl       <= 0;
            IdEx_rf_we           <= 0;
            IdEx_rd              <= 0;
            IdEx_rs1_fwd_from_Ma <= 0;
            IdEx_rs2_fwd_from_Ma <= 0;
            IdEx_rs1_fwd_from_Wb <= 0;
            IdEx_rs2_fwd_from_Wb <= 0;
            IdEx_xrs1            <= 0;
            IdEx_xrs2            <= 0;
            IdEx_imm             <= 0;
        end else if (!stall_i) begin
            IdEx_v               <=   Id_v              ;
            IdEx_pc              <= IfId_pc             ;
            IdEx_ir              <= IfId_ir             ;
            IdEx_load            <= IfId_load           ;
            IdEx_store           <= IfId_store          ;
            IdEx_bru_ctrl        <=   Id_bru_ctrl       ;
            IdEx_alu_ctrl        <=   Id_alu_ctrl       ;
            IdEx_store_ctrl      <=   Id_store_ctrl     ;
            IdEx_load_ctrl       <=   Id_load_ctrl      ;
            IdEx_rf_we           <= IfId_rf_we          ;
            IdEx_rd              <= IfId_rd             ;
            IdEx_rs1_fwd_from_Ma <=   Id_rs1_fwd_from_Ma;
            IdEx_rs2_fwd_from_Ma <=   Id_rs2_fwd_from_Ma;
            IdEx_rs1_fwd_from_Wb <=   Id_rs1_fwd_from_Wb;
            IdEx_rs2_fwd_from_Wb <=   Id_rs2_fwd_from_Wb;
            IdEx_xrs1            <=   Id_xrs1_t         ;
            IdEx_xrs2            <=   Id_xrs2_t         ;
            IdEx_imm             <=   Id_imm            ;
        end
    end

    /***** EX Stage *****/
    /* Data Forwarding */
    wire [XLEN-1:0] Ex_xrs1 = (IdEx_rs1_fwd_from_Ma) ? ExMa_rslt : (IdEx_rs1_fwd_from_Wb) ? MaWb_rslt : IdEx_xrs1;
    wire [XLEN-1:0] Ex_xrs2 = (IdEx_rs2_fwd_from_Ma) ? ExMa_rslt : (IdEx_rs2_fwd_from_Wb) ? MaWb_rslt : IdEx_xrs2;

    /* BRU: Branch Resolution Unit */
    wire            Ex_tkn   ;
    wire [XLEN-1:0] Ex_tkn_pc;
    bru #(
        .XLEN(XLEN)
    ) bru0 (
        .in1     (  Ex_xrs1    ),
        .in2     (  Ex_xrs2    ),
        .pc      (IdEx_pc      ),
        .imm     (IdEx_imm     ),
        .bru_ctrl(IdEx_bru_ctrl),
        .tkn     (  Ex_tkn     ),
        .tkn_pc  (  Ex_tkn_pc  )
    );

    /* ALU: Arithmetic Logic Unit */
    wire [XLEN-1:0] Ex_alu_rslt;
    alu #(
        .XLEN(XLEN)
    ) alu0 (
        .in1      (  Ex_xrs1    ), // x[rs1] or pc
        .in2      (  Ex_xrs2    ), // x[rs2] or imm
        .alu_ctrl (IdEx_alu_ctrl),
        .out      (  Ex_alu_rslt)
    );

    wire [XLEN-1:0] Ex_rslt = Ex_alu_rslt;

    /* Store Unit */
    /* Valid */
    assign dmem_wvalid_o = (Ex_v && IdEx_store);

    /* Address Generation */
    assign dmem_addr_o = Ex_xrs1+IdEx_imm;
    wire [$clog2(XBYTES)-1:0] Ex_dmem_offset = dmem_addr_o[$clog2(XBYTES)-1:0];

    /* Store Data */
    wire [XLEN-1:0] Ex_sb = (IdEx_store_ctrl[0]) ? {4{Ex_xrs2[ 7:0]}} : 0;
    wire [XLEN-1:0] Ex_sh = (IdEx_store_ctrl[1]) ? {2{Ex_xrs2[15:0]}} : 0;
    wire [XLEN-1:0] Ex_sw = (IdEx_store_ctrl[2]) ?    Ex_xrs2         : 0;
    assign dmem_wdata_o = (Ex_sb | Ex_sh | Ex_sw);

    /* Write Strb */
    wire [XBYTES-1:0] Ex_sb_wstrb = (IdEx_store_ctrl[0]) ? 4'b0001 <<  Ex_dmem_offset           : 0;
    wire [XBYTES-1:0] Ex_sh_wstrb = (IdEx_store_ctrl[1]) ? 4'b0011 << {Ex_dmem_offset[1], 1'b0} : 0;
    wire [XBYTES-1:0] Ex_sw_wstrb = (IdEx_store_ctrl[2]) ? 4'b1111                              : 0;
    assign dmem_wstrb_o = (Ex_sb_wstrb | Ex_sh_wstrb | Ex_sw_wstrb);

    /***** MA Stage *****/
    always @(posedge clk_i) begin
        if (!rst_ni) begin
            ExMa_v           <= 0;
            ExMa_pc          <= 0;
            ExMa_ir          <= 0;
            ExMa_tkn         <= 0;
            ExMa_tkn_pc      <= 0;
            ExMa_load        <= 0;
            ExMa_load_ctrl   <= 0;
            ExMa_dmem_offset <= 0;
            ExMa_rf_we       <= 0;
            ExMa_rd          <= 0;
            ExMa_rslt        <= 0;
        end else if (!stall_i) begin
            ExMa_v           <=   Ex_v          ;
            ExMa_pc          <= IdEx_pc         ;
            ExMa_ir          <= IdEx_ir         ;
            ExMa_tkn         <=   Ex_tkn        ;
            ExMa_tkn_pc      <=   Ex_tkn_pc     ;
            ExMa_load        <= IdEx_load       ;
            ExMa_load_ctrl   <= IdEx_load_ctrl  ;
            ExMa_dmem_offset <=   Ex_dmem_offset;
            ExMa_rf_we       <= IdEx_rf_we      ;
            ExMa_rd          <= IdEx_rd         ;
            ExMa_rslt        <=   Ex_rslt       ;
        end
    end

    /* Load Unit */
    wire [31:0] Ma_lw_t = dmem_rdata_i;
    wire [15:0] Ma_lh_t = (ExMa_dmem_offset[1]) ? Ma_lw_t[31:16] : Ma_lw_t[15:0];
    wire  [7:0] Ma_lb_t = (ExMa_dmem_offset[0]) ? Ma_lh_t[15: 8] : Ma_lh_t[ 7:0];
    wire [XLEN-1:0] Ma_lb  = (ExMa_load_ctrl[1]) ? {{24{ExMa_load_ctrl[0] && Ma_lb_t[ 7]}}, Ma_lb_t} : 0;
    wire [XLEN-1:0] Ma_lh  = (ExMa_load_ctrl[2]) ? {{16{ExMa_load_ctrl[0] && Ma_lh_t[15]}}, Ma_lh_t} : 0;
    wire [XLEN-1:0] Ma_lw  = (ExMa_load_ctrl[3]) ?                                          Ma_lw_t  : 0;
    wire [XLEN-1:0] Ma_load_rslt = (Ma_lb | Ma_lh | Ma_lw);

    wire [XLEN-1:0] Ma_rslt = (ExMa_load) ? Ma_load_rslt : ExMa_rslt;

    /***** WB Stage *****/
    always @(posedge clk_i) begin
        if (!rst_ni) begin
            MaWb_v     <= 0;
            MaWb_pc    <= 0;
            MaWb_ir    <= 0;
            MaWb_rf_we <= 0;
            MaWb_rd    <= 0;
            MaWb_rslt  <= 0;
        end else if (!stall_i) begin
            MaWb_v     <= Ma_v      ;
            MaWb_pc    <= ExMa_pc   ;
            MaWb_ir    <= ExMa_ir   ;
            MaWb_rf_we <= ExMa_rf_we;
            MaWb_rd    <= ExMa_rd   ;
            MaWb_rslt  <= Ma_rslt   ;
        end
    end

    /***** for Debug *****/
    wire valid_instr = Wb_v;

endmodule

`resetall
