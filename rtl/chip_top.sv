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

    // ============================================================
    // TAP controller
    // ============================================================
    logic shift_dr_bisr, capture_dr_bisr, update_dr_bisr;
    logic shift_dr_mbist, capture_dr_mbist, update_dr_mbist;
    logic [3:0] ir_out;

    logic tdi_dr;
    logic tdo_chain;  // final return from IJTAG chain

    tap_controller tap0 (
        .TCK            (TCK),
        .TMS            (TMS),
        .TRST           (TRST),
        .TDI            (TDI),
        .TDO            (TDO),        // final output
        .ir_out         (ir_out),

        .shift_dr_bisr  (shift_dr_bisr),
        .capture_dr_bisr(capture_dr_bisr),
        .update_dr_bisr (update_dr_bisr),

        .shift_dr_mbist (shift_dr_mbist),
        .capture_dr_mbist(capture_dr_mbist),
        .update_dr_mbist(update_dr_mbist),

        .tdi_dr         (tdi_dr),
        .tdo_dr         (tdo_chain)   // comes back from chain
    );

    // ============================================================
    // ----------- BISR SIB + BISR -------------------------------
    // ============================================================
    logic bisr_tdi;
    logic bisr_tdo_child;   // from BISR
    logic bisr_tdo_sib;     // from SIB (output to next stage)
    logic bisr_enable;

    sib bisr_sib (
        .tck        (TCK),
        .trst_n     (~TRST),
        .tdi        (tdi_dr),
        .tdo        (bisr_tdo_sib),     // SIB output

        .shift_dr   (shift_dr_bisr),
        .capture_dr (capture_dr_bisr),
        .update_dr  (update_dr_bisr),

        .child_tdi  (bisr_tdi),
        .child_tdo  (bisr_tdo_child),   // from BISR

        .sib_bit    (bisr_enable)
    );

    bisr #(
        .DATA_WIDTH(BISR_WIDTH),
        .MEM_DEPTH (MEM_DEPTH)
    ) bisr0 (
        .tck        (TCK),
        .trst_n     (~TRST),
        .tdi        (bisr_tdi),
        .tdo        (bisr_tdo_child),   // ONLY drives child net

        .capture_dr (capture_dr_bisr),
        .shift_dr   (shift_dr_bisr),
        .update_dr  (update_dr_bisr),

        .enable     (bisr_enable)
    );

    // ============================================================
    // ----------- MBIST SIB + MBIST ------------------------------
    // ============================================================
    logic mbist_tdi;
    logic mbist_tdo_child;
    logic mbist_tdo_sib;
    logic mbist_enable;

    sib mbist_sib (
        .tck        (TCK),
        .trst_n     (~TRST),
        .tdi        (bisr_tdo_sib),     // chained from previous SIB
        .tdo        (mbist_tdo_sib),    // SIB output

        .shift_dr   (shift_dr_mbist),
        .capture_dr (capture_dr_mbist),
        .update_dr  (update_dr_mbist),

        .child_tdi  (mbist_tdi),
        .child_tdo  (mbist_tdo_child),

        .sib_bit    (mbist_enable)
    );

    dummy_mbist #(
        .WIDTH(MBIST_WIDTH)
    ) mbist0 (
        .tck      (TCK),
        .trst_n   (~TRST),
        .tdi_in   (mbist_tdi),
        .tdo_out  (mbist_tdo_child),   // ONLY drives child net
        .enable   (mbist_enable)
    );

    // ============================================================
    // Final chain output back to TAP
    // ============================================================
    assign tdo_chain = mbist_tdo_sib;

endmodule
