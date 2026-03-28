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
    // Separate instrument shift registers
    // ---------------------------
    logic [INSTR_SHIFT_WIDTH-1:0] bisr_shift_reg;
    logic [INSTR_SHIFT_WIDTH-1:0] mbist_shift_reg;

    // ---------------------------
    // Single BISR
    // ---------------------------
    bisr #(
        .DATA_WIDTH(BISR_WIDTH)
    ) bisr0 (
        .tck(TCK),
        .trst_n(TRST),
        .tdi(tap_tdo),
        .tdo(bisr_shift_reg[0]), // LSB of BISR shift register
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
        .tdi_in(bisr_shift_reg[0]),  // serial input from BISR
        .tdo_out(mbist_shift_reg[0])  // serial output to TDO
    );

    // ---------------------------
    // TDO output comes from last instrument
    // ---------------------------
    assign TDO = mbist_shift_reg[0];

    // ---------------------------
    // Single memory array for BISR
    // ---------------------------
    logic [BISR_WIDTH-1:0] memory [0:255]; // one memory block

endmodule
