module chip_top (
    input  logic TCK,
    input  logic TMS,
    input  logic TRST,
    input  logic TDI,
    output logic TDO
);

    logic shift_dr, capture_dr, update_dr;
    logic tap_tdo;

    // TAP controller (must expose DR state signals)
    tap_controller tap0 (
        .TCK(TCK),
        .TMS(TMS),
        .TRST(TRST),
        .TDI(TDI),
        .TDO(tap_tdo),

        .shift_dr(shift_dr),
        .capture_dr(capture_dr),
        .update_dr(update_dr)
    );

    // IJTAG network
    ujtag_bus bus0 (
        .tck(TCK),
        .trst_n(TRST),
        .tdi(tap_tdo),
        .tdo(TDO),

        .shift_dr(shift_dr),
        .capture_dr(capture_dr),
        .update_dr(update_dr)
    );

endmodule
