module chip_top (
    input  logic tck,
    input  logic tms,
    input  logic tdi,
    input  logic trst_n,
    output logic tdo
);

    // --------------------------------------------------------------------
    // TAP controller instance
    // --------------------------------------------------------------------
    logic [31:0] ir;      // Instruction register (optional)
    logic [31:0] dr;      // Data register (for Shift-DR)
    logic tap_tdo;

    tap_controller tap0 (
        .tck    (tck),
        .tms    (tms),
        .tdi    (tdi),
        .trst_n (trst_n),
        .tdo    (tap_tdo),
        .ir_out (ir),
        .dr_out (dr)
    );

    // --------------------------------------------------------------------
    // IJTAG Control Register (for SIB enable)
    // --------------------------------------------------------------------
    logic sib_enable;

    ijtag_ctrl_reg ctrl0 (
        .tck        (tck),
        .trst_n     (trst_n),
        .tdi_in     (tap_tdo),      // TAP shifts control bits first
        .sib_enable (sib_enable),
        .tdo_out    (tdo)           // TDO after control (SIB) optional
    );

    // --------------------------------------------------------------------
    // SIB for BISR
    // --------------------------------------------------------------------
    logic bisr_tdi, bisr_tdo;

    sib #(
        .WIDTH(8)   // Width of BISR shift register
    ) sib_bisr (
        .tck        (tck),
        .trst_n     (trst_n),
        .sib_enable (sib_enable),
        .tdi_in     (tap_tdo),      // comes from TAP/ctrl chain
        .tdo_out    (bisr_tdo),
        .instr_data_in(),            // optional initial value
        .instr_data_out()            // optional observation
    );

    // --------------------------------------------------------------------
    // BISR instrument
    // --------------------------------------------------------------------
    bisr #(
        .DATA_WIDTH(8)
    ) bisr0 (
        .tck        (tck),
        .trst_n     (trst_n),
        .tdi        (bisr_tdi),
        .tdo        (bisr_tdo)
        // optional: memory interface if you want to simulate repair
    );

endmodule
