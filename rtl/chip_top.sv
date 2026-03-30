`include "memory.sv"
`include "dummy_mbist.sv"
`include "ujtag_bus.sv"
`include "bisr.sv"
`include "sib.sv"
`include "tap_controller.sv"

module chip_top (
    input  logic TCK,
    input  logic TMS,
    input  logic TRST,
    input  logic TDI,
    output logic TDO
);

    // ---------------------------
    // TAP ↔ IJTAG connections
    // ---------------------------
    logic shift_dr, capture_dr, update_dr;
    logic tdi_to_ijtag;
    logic tdo_from_ijtag;

    // ---------------------------
    // TAP Controller
    // ---------------------------
    tap_controller tap0 (
        .TCK(TCK),
        .TMS(TMS),
        .TRST(TRST),
        .TDI(TDI),
        .TDO(TDO),

        .ir_out(),

        .shift_dr(shift_dr),
        .capture_dr(capture_dr),
        .update_dr(update_dr),

        .tdi_dr(tdi_to_ijtag),
        .tdo_dr(tdo_from_ijtag)
    );

    // ---------------------------
    // IJTAG Network (SIB + BISR + MBIST)
    // ---------------------------
    ujtag_bus bus0 (
        .tck(TCK),
        .trst_n(TRST),
        .tdi(tdi_to_ijtag),
        .tdo(tdo_from_ijtag),

        .shift_dr(shift_dr),
        .capture_dr(capture_dr),
        .update_dr(update_dr)
    );

endmodule
