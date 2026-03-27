module chip_top #(
    parameter IR_WIDTH    = 4,
    parameter DR_WIDTH    = 32,
    parameter BISR_WIDTH  = 8,
    parameter MBIST_WIDTH = 16,
    parameter IDCODE      = 32'h1234ABCD
)(
    input  logic TCK,
    input  logic TMS,
    input  logic TRST,
    input  logic TDI,
    output logic TDO
);

    // --------------------------------------------------------------------
    // TAP controller instance
    // --------------------------------------------------------------------
    logic [IR_WIDTH-1:0] ir_out;
    logic [DR_WIDTH-1:0] dr_out;
    logic bypass_enable;
    logic tap_tdo;

    tap_controller #(
        .IR_WIDTH(IR_WIDTH),
        .DR_WIDTH(DR_WIDTH),
        .IDCODE(IDCODE)
    ) tap0 (
        .TCK(TCK),
        .TMS(TMS),
        .TRST(TRST),
        .TDI(TDI),
        .TDO(tap_tdo),
        .ir_out(ir_out),
        .dr_out(dr_out),
        .bypass_enable(bypass_enable)
    );

    // --------------------------------------------------------------------
    // SIB for BISR (with shiftable enable)
    // --------------------------------------------------------------------
    logic bisr_tdo;
    logic [BISR_WIDTH-1:0] bisr_instr_data;

    sib #(
        .WIDTH(BISR_WIDTH)
    ) sib_bisr (
        .tck(TCK),
        .trst_n(TRST),
        .tdi_in(tap_tdo),
        .tdo_out(bisr_tdo),
        .instr_data_in('0),
        .instr_data_out(bisr_instr_data)
    );

    // Extract SIB enable from MSB of shift register
    wire bisr_enable = bisr_instr_data[BISR_WIDTH-1];

    // --------------------------------------------------------------------
    // BISR instrument
    // --------------------------------------------------------------------
    logic bisr_out;

    bisr #(
        .DATA_WIDTH(BISR_WIDTH-1)  // remaining bits after enable
    ) bisr0 (
        .tck(TCK),
        .trst_n(TRST),
        .tdi(bisr_tdo),
        .tdo(bisr_out),
        .enable(bisr_enable)
    );

    // --------------------------------------------------------------------
    // Dummy MBIST module
    // --------------------------------------------------------------------
    dummy_mbist #(
        .WIDTH(MBIST_WIDTH)
    ) mbist0 (
        .tck(TCK),
        .trst_n(TRST),
        .tdi_in(bisr_out),
        .tdo_out(TDO)
    );

endmodule
