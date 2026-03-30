module sib (
    input  logic tck,
    input  logic trst_n,

    input  logic tdi,
    output logic tdo,

    input  logic shift_dr,
    input  logic update_dr,
    input  logic capture_dr,

    // downstream chain
    input  logic child_tdo,
    output logic child_tdi
);

    logic sib_bit;        // latched enable
    logic sib_shift_reg;  // shift register

    // ---------------------------
    // Shift register behavior
    // ---------------------------
    always_ff @(posedge tck or negedge trst_n) begin
        if (!trst_n)
            sib_shift_reg <= 1'b0;
        else if (capture_dr)
            sib_shift_reg <= sib_bit;
        else if (shift_dr)
            sib_shift_reg <= tdi;
    end

    // ---------------------------
    // Update enable
    // ---------------------------
    always_ff @(posedge tck or negedge trst_n) begin
        if (!trst_n)
            sib_bit <= 1'b0;
        else if (update_dr)
            sib_bit <= sib_shift_reg;
    end

    // ---------------------------
    // Muxing behavior
    // ---------------------------
    assign child_tdi = sib_shift_reg;

    assign tdo = (sib_bit) ? child_tdo : sib_shift_reg;

endmodule
