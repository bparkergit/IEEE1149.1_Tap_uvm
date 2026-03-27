module chip_top #(
    parameter IR_WIDTH            = 4,
    parameter BISR_WIDTH          = 8,     // BISR data bits
    parameter NUM_SEGMENT_BITS    = 2,     // Segment select bits
    parameter MBIST_WIDTH         = 16,
    parameter NUM_INSTRUMENTS     = 2,     // BISR + MBIST
    parameter INSTR_SHIFT_WIDTH   = 32,    // max width of instrument shift register
    parameter IDCODE              = 32'h1234ABCD
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
    logic bypass_enable;
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
        .dr_out(dr_shift),
        .bypass_enable(bypass_enable)
    );

    // ---------------------------
    // IJTAG / Instrument Bus
    // ---------------------------
    logic [NUM_INSTRUMENTS-1:0][INSTR_SHIFT_WIDTH-1:0] instr_shift;
    logic ijtag_tdo;

    ijtag_bus #(
        .NUM_INSTR(NUM_INSTRUMENTS),
        .MAX_WIDTH(INSTR_SHIFT_WIDTH)
    ) bus0 (
        .tck(TCK),
        .trst_n(TRST),
        .tdi_in(tap_tdo),
        .tdo_out(ijtag_tdo)
    );

    // ---------------------------
    // Instruments
    // ---------------------------
    // BISR
    bisr #(
        .DATA_WIDTH(BISR_WIDTH),
        .NUM_SEGMENT_BITS(NUM_SEGMENT_BITS)
    ) bisr0 (
        .tck(TCK),
        .trst_n(TRST),
        .tdi(ijtag_tdo),
        .tdo(instr_shift[0][0]),
        .ir(ir_out),
        .user_dr_shift(dr_shift[BISR_WIDTH + NUM_SEGMENT_BITS-1:0])
    );

    // Dummy MBIST
    dummy_mbist #(
        .WIDTH(MBIST_WIDTH)
    ) mbist0 (
        .tck(TCK),
        .trst_n(TRST),
        .tdi_in(instr_shift[0][0]),
        .tdo_out(TDO)
    );

endmodule
