module chip_top #(
    parameter IR_WIDTH          = 4,
    parameter BISR_WIDTH        = 8,
    parameter MBIST_WIDTH       = 16,
    parameter INSTR_SHIFT_WIDTH = 32,
    parameter IDCODE            = 32'h1234ABCD
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
    logic [IR_WIDTH-1:0] ir_out;
    logic [INSTR_SHIFT_WIDTH-1:0] dr_shift;
    logic tap_tdo;

    tap_controller #(
        .IR_WIDTH(IR_WIDTH),
        .DR_WIDTH(INSTR_SHIFT_WIDTH),
        .IDCODE(IDCODE)
    ) tap0 (
        .TCK(TCK),
        .TMS(TMS),
        .TRST(TRST),
        .TDI(TDI),
        .TDO(tap_tdo),
        .ir_out(ir_out),
        .dr_out(dr_shift)
    );

    // ---------------------------
    // IJTAG bus (instrument wrapper)
    // ---------------------------
    logic bisr_tdo, mbist_tdo;

    ujtag_bus #(
        .BISR_WIDTH(BISR_WIDTH),
        .MBIST_WIDTH(MBIST_WIDTH)
    ) bus0 (
        .tck(TCK),
        .trst_n(TRST),
        .tdi_in(tap_tdo),
        .tdo_bisr(bisr_tdo),
        .tdo_mbist(mbist_tdo),
        .ir(ir_out),
        .dr_shift(dr_shift)
    );

    // ---------------------------
    // TDO output from last instrument
    // ---------------------------
    assign TDO = mbist_tdo;

endmodule
