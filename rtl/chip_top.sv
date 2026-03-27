module chip_top #(
    parameter IR_WIDTH          = 4,
    parameter BISR_WIDTH        = 8,     // width of BISR data
    parameter MBIST_WIDTH       = 16,    // MBIST width
    parameter INSTR_SHIFT_WIDTH = 32,    // max width for instrument bus shift register
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
    logic [1:0][INSTR_SHIFT_WIDTH-1:0] instrument_shift_reg;
    logic ijtag_tdo;

    ijtag_bus #(
        .NUM_INSTR(2),
        .MAX_WIDTH(INSTR_SHIFT_WIDTH)
    ) bus0 (
        .tck(TCK),
        .trst_n(TRST),
        .tdi_in(tap_tdo),
        .tdo_out(ijtag_tdo),
        .instrument_shift_reg(instrument_shift_reg)
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
        .tdo(instrument_shift_reg[0][0]), // BISR serial out
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
        .tdi_in(instrument_shift_reg[0][0]),
        .tdo_out(TDO)
    );

    // ---------------------------
    // Single memory array
    // ---------------------------
    logic [BISR_WIDTH-1:0] memory [0:255]; // one memory block

endmodule
