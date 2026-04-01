`include "memory.sv"
`include "dummy_mbist.sv"
`include "bisr.sv"
`include "sib.sv"
`include "tap_controller.sv"

module chip_top #(
    parameter BISR_WIDTH  = 8,
    parameter MEM_DEPTH   = 256,
    parameter MBIST_WIDTH = 16
)(
    input  logic TCK,
    input  logic TMS,
    input  logic TRST,
    input  logic TDI,
    output logic TDO
);

    // ---------------------------
    // TAP controller
    // ---------------------------
    logic shift_dr_bisr, capture_dr_bisr, update_dr_bisr;
    logic shift_dr_mbist, capture_dr_mbist, update_dr_mbist;
    logic [3:0] ir_out;
    logic tdi_dr, tdo_dr;

    tap_controller tap0 (
        .TCK           (TCK),
        .TMS           (TMS),
        .TRST          (TRST),
        .TDI           (TDI),
        .TDO           (tdo_dr),
        .ir_out        (ir_out),
        .shift_dr_bisr (shift_dr_bisr),
        .capture_dr_bisr(capture_dr_bisr),
        .update_dr_bisr(update_dr_bisr),
        .shift_dr_mbist(shift_dr_mbist),
        .capture_dr_mbist(capture_dr_mbist),
        .update_dr_mbist(update_dr_mbist),
        .tdi_dr        (tdi_dr),
        .tdo_dr        (tdo_dr)
    );

    // ---------------------------
    // BISR SIB + DR
    // ---------------------------
    logic bisr_tdi, bisr_tdo;
    logic bisr_enable;

    sib bisr_sib (
        .tck       (TCK),
        .trst_n    (~TRST),
        .tdi       (tdi_dr),
        .tdo       (bisr_tdo),
        .shift_dr  (shift_dr_bisr),
        .capture_dr(capture_dr_bisr),
        .update_dr (update_dr_bisr),
        .child_tdi (bisr_tdi),
        .child_tdo (/* unused for last segment */),
        .sib_bit   (bisr_enable)
    );

    bisr #(
        .DATA_WIDTH(BISR_WIDTH),
        .MEM_DEPTH (MEM_DEPTH)
    ) bisr0 (
        .tck        (TCK),
        .trst_n     (~TRST),
        .tdi        (bisr_tdi),
        .tdo        (bisr_tdo),
        .capture_dr (capture_dr_bisr),
        .shift_dr   (shift_dr_bisr),
        .update_dr  (update_dr_bisr),
        .enable     (bisr_enable)
    );

    // ---------------------------
    // MBIST SIB + DR
    // ---------------------------
    logic mbist_tdi, mbist_tdo;
    logic mbist_enable;

    sib mbist_sib (
        .tck       (TCK),
        .trst_n    (~TRST),
        .tdi       (bisr_tdo), // chained from BISR TDO
        .tdo       (mbist_tdo),
        .shift_dr  (shift_dr_mbist),
        .capture_dr(capture_dr_mbist),
        .update_dr (update_dr_mbist),
        .child_tdi (mbist_tdi),
        .child_tdo (/* unused */),
        .sib_bit   (mbist_enable)
    );

    dummy_mbist #(
        .WIDTH(MBIST_WIDTH)
    ) mbist0 (
        .tck      (TCK),
        .trst_n   (~TRST),
        .tdi_in   (mbist_tdi),
        .tdo_out  (mbist_tdo),
        .enable   (mbist_enable)
    );

    // ---------------------------
    // TAP TDO is last SIB TDO
    // ---------------------------
    assign TDO = mbist_tdo;

endmodule
