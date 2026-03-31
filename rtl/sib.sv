// ================================================================
// SIB (Segment Insertion Bit) for selecting downstream block
// Simple, clean version for BISR/MBIST selection
// ================================================================
module sib (
    input  logic tck,
    input  logic trst_n,

    input  logic tdi,
    output logic tdo,

    input  logic shift_dr,
    input  logic capture_dr,
    input  logic update_dr,

    // downstream chain
    input  logic child_tdo,
    output logic child_tdi,
    output logic sib_bit
);

    // ---------------------------
    // Registers
    // ---------------------------
    logic sib_shift_reg;  // temporary shift register during SHIFT_DR


    // ---------------------------
    // Shift register behavior
    // ---------------------------
    always_ff @(posedge tck or negedge trst_n) begin
        if (!trst_n)
            sib_shift_reg <= 1'b0;
        else if (capture_dr)
            sib_shift_reg <= sib_bit;  // preload current enable
        else if (shift_dr)
            sib_shift_reg <= tdi;      // shift in new value
    end

    // ---------------------------
    // Latch enable on UPDATE_DR
    // ---------------------------
    always_ff @(posedge tck or negedge trst_n) begin
        if (!trst_n)
            sib_bit <= 1'b0;
        else if (update_dr)
            sib_bit <= sib_shift_reg;
    end

    // ---------------------------
    // Pass TDI downstream
    // ---------------------------
    assign child_tdi = tdi;

    // ---------------------------
    // TDO mux
    // ---------------------------
    assign tdo = (sib_bit) ? child_tdo : sib_shift_reg;

endmodule
