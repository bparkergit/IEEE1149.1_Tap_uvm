module chip_top #(
    parameter IR_WIDTH = 4,
    parameter DR_WIDTH = 32,
    parameter BISR_WIDTH = 8,
    parameter IDCODE   = 32'h1234ABCD
)(
    input  logic TCK,
    input  logic TMS,
    input  logic TRST,
    input  logic TDI,
    output logic TDO
);

    // --------------------------------------------------------------------
    // TAP controller instance
    // --------------------------------------------------------------------
    logic [IR_WIDTH-1:0] ir_out;
    logic [DR_WIDTH-1:0] dr_out;
    logic bypass_enable;
    logic tap_tdo;

    tap_controller #(
        .IR_WIDTH(IR_WIDTH),
        .DR_WIDTH(DR_WIDTH),
        .IDCODE(IDCODE)
    ) tap0 (
        .TCK(TCK),
        .TMS(TMS),
        .TRST(TRST),
        .TDI(TDI),
        .TDO(tap_tdo),
        .ir_out(ir_out),
        .dr_out(dr_out),
        .bypass_enable(bypass_enable)
    );

    // --------------------------------------------------------------------
    // SIB (Serial Instrument Bus) for BISR
    // --------------------------------------------------------------------
    logic bisr_tdo;
    logic sib_enable;

    // Enable BISR only when USER_DR instruction is selected
    assign sib_enable = (ir_out == 4'b0010);  

    sib #(
        .WIDTH(BISR_WIDTH)
    ) sib_bisr (
        .tck(TCK),
        .trst_n(TRST),
        .sib_enable(sib_enable),
        .tdi_in(tap_tdo),          // TAP drives SIB input
        .tdo_out(bisr_tdo),
        .instr_data_in(),           // optional initial value
        .instr_data_out()           // optional observation
    );

    // --------------------------------------------------------------------
    // BISR instrument
    // --------------------------------------------------------------------
    bisr #(
        .DATA_WIDTH(BISR_WIDTH)
    ) bisr0 (
        .tck(TCK),
        .trst_n(TRST),
        .tdi(bisr_tdo),  // SIB output drives BISR input
        .tdo(TDO)        // BISR output is chip TDO
    );

endmodule
