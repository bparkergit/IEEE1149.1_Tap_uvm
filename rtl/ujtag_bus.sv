module ujtag_bus #(
    parameter BISR_WIDTH  = 8,
    parameter MEM_DEPTH   = 256,
    parameter MBIST_WIDTH = 16
)(
    input  logic tck,
    input  logic trst_n,
    input  logic tdi,
    output logic tdo,

    input  logic shift_dr,
    input  logic capture_dr,
    input  logic update_dr
);

    // ---------------------------
    // Internal chain wires
    // ---------------------------
    logic sib_bisr_tdo, sib_mbist_tdo;
    logic bisr_tdi, bisr_tdo;
    logic mbist_tdi, mbist_tdo;

    // ---------------------------
    // SIB for BISR
    // ---------------------------
    sib sib_bisr (
        .tck(tck),
        .trst_n(trst_n),
        .tdi(tdi),
        .tdo(sib_bisr_tdo),

        .shift_dr(shift_dr),
        .capture_dr(capture_dr),
        .update_dr(update_dr),

        .child_tdi(bisr_tdi),
        .child_tdo(bisr_tdo)
    );

    // ---------------------------
    // BISR
    // ---------------------------
    bisr #(
        .DATA_WIDTH(BISR_WIDTH),
        .MEM_DEPTH(MEM_DEPTH)
    ) bisr0 (
        .tck(tck),
        .trst_n(trst_n),
        .tdi(bisr_tdi),
        .tdo(bisr_tdo),
        .shift_dr(shift_dr),
        .capture_dr(capture_dr),
        .update_dr(update_dr)
    );

    // ---------------------------
    // SIB for MBIST
    // ---------------------------
    sib sib_mbist (
        .tck(tck),
        .trst_n(trst_n),
        .tdi(sib_bisr_tdo),
        .tdo(sib_mbist_tdo),

        .shift_dr(shift_dr),
        .capture_dr(capture_dr),
        .update_dr(update_dr),

        .child_tdi(mbist_tdi),
        .child_tdo(mbist_tdo)
    );

    // ---------------------------
    // Dummy MBIST
    // ---------------------------
    dummy_mbist #(
        .WIDTH(MBIST_WIDTH)
    ) mbist0 (
        .tck(tck),
        .trst_n(trst_n),
        .tdi_in(mbist_tdi),
        .tdo_out(mbist_tdo)
    );

    // ---------------------------
    // Final TDO
    // ---------------------------
    assign tdo = sib_mbist_tdo;

endmodule
