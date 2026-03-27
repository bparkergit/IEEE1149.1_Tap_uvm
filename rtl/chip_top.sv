module chip_top #(
    parameter IR_WIDTH    = 4,
    parameter DR_WIDTH    = 32,  // total DR width for BISR + SIB
    parameter BISR_WIDTH  = 8,   // BISR data width (excluding SIB)
    parameter NUM_SIB_BITS = 2,  // number of SIB bits
    parameter MBIST_WIDTH = 16,
    parameter IDCODE      = 32'h1234ABCD
)(
    input  logic TCK,
    input  logic TMS,
    input  logic TRST,
    input  logic TDI,
    output logic TDO
);

    // ---------------------------
    // TAP controller instance
    // ---------------------------
    logic [IR_WIDTH-1:0] ir_out;
    logic [DR_WIDTH-1:0] user_dr_shift;
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
        .dr_out(user_dr_shift),
        .bypass_enable(bypass_enable)
    );

    // ---------------------------
    // BISR instrument
    // ---------------------------
    logic bisr_tdo;
    logic [BISR_WIDTH-1:0] bisr_data;
    logic [NUM_SIB_BITS-1:0] sib_bits;

    bisr #(
        .DATA_WIDTH(BISR_WIDTH),
        .NUM_SIB_BITS(NUM_SIB_BITS)
    ) bisr0 (
        .tck(TCK),
        .trst_n(TRST),
        .tdi(tap_tdo),         // TAP drives BISR
        .tdo(bisr_tdo),
        .ir(ir_out),
        .user_dr_shift(user_dr_shift)
    );

    // ---------------------------
    // Dummy MBIST module
    // ---------------------------
    dummy_mbist #(
        .WIDTH(MBIST_WIDTH)
    ) mbist0 (
        .tck(TCK),
        .trst_n(TRST),
        .tdi_in(bisr_tdo),
        .tdo_out(TDO)
    );

endmodule
