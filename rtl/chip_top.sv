module chip_top #(
    parameter IR_WIDTH          = 4,
    parameter BISR_WIDTH        = 8,     // width of BISR data
    parameter MBIST_WIDTH       = 16,    // MBIST width
    parameter INSTR_SHIFT_WIDTH = 32,    // max width for IJTAG bus
    parameter IDCODE            = 32'h1234ABCD
)(
    input  logic TCK,
    input  logic TMS,
    input  logic TRST,
    input  logic TDI,
    output logic TDO
);

    // ---------------------------
    // TAP Controller
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
    // IJTAG / Instrument Bus
    // ---------------------------
    logic [1:0][INSTR_SHIFT_WIDTH-1:0] instr_shift;
    logic ijtag_tdo;

    ijtag_bus #(
        .NUM_INSTR(2),
        .MAX_WIDTH(INSTR_SHIFT_WIDTH)
    ) bus0 (
        .tck(TCK),
        .trst_n(TRST),
        .tdi_in(tap_tdo),
        .tdo_out(ijtag_tdo)
    );

    // ---------------------------
    // Single BISR
    // ---------------------------
    bisr #(
        .DATA_WIDTH(BISR_WIDTH)
    ) bisr0 (
        .tck(TCK),
        .trst_n(TRST),
        .tdi(ijtag_tdo),
        .tdo(instr_shift[0][0]),
        .ir(ir_out),
        .user_dr_shift(dr_shift[BISR_WIDTH-1:0])
    );

    // ---------------------------
    // Dummy MBIST controller
    // ---------------------------
    dummy_mbist #(
        .WIDTH(MBIST_WIDTH)
    ) mbist0 (
        .tck(TCK),
        .trst_n(TRST),
        .tdi_in(instr_shift[0][0]),
        .tdo_out(TDO)
    );

    // ---------------------------
    // Single memory array
    // ---------------------------
    logic [BISR_WIDTH-1:0] memory [0:255]; // one memory block

endmodule
