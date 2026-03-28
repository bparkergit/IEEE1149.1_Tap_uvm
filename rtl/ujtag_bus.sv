module ujtag_bus #(
    parameter BISR_WIDTH  = 8,
    parameter MBIST_WIDTH = 16
)(
    input  logic tck,
    input  logic trst_n,
    input  logic tdi_in,
    output logic tdo_bisr,
    output logic tdo_mbist,
    input  logic [3:0] ir,
    input  logic [31:0] dr_shift
);

    // ---------------------------
    // SIB enables (instrument select)
    // ---------------------------
    logic bisr_enable, mbist_enable;

    always_ff @(posedge tck or negedge trst_n) begin
        if (!trst_n) begin
            bisr_enable  <= 1'b0;
            mbist_enable <= 1'b0;
        end else if (ir == 4'b0010) begin
            bisr_enable  <= dr_shift[0];
            mbist_enable <= dr_shift[1];
        end
    end

    // ---------------------------
    // Instruments
    // ---------------------------
    bisr #(
        .DATA_WIDTH(BISR_WIDTH)
    ) bisr0 (
        .tck(tck),
        .trst_n(trst_n),
        .tdi(tdi_in),
        .tdo(tdo_bisr),
        .ir(ir),
        .user_dr_shift(dr_shift[BISR_WIDTH-1:0]),
        .enable(bisr_enable)
    );

    dummy_mbist #(
        .WIDTH(MBIST_WIDTH)
    ) mbist0 (
        .tck(tck),
        .trst_n(trst_n),
        .tdi_in(tdo_bisr),
        .tdo_out(tdo_mbist),
        .enable(mbist_enable)
    );

endmodule
