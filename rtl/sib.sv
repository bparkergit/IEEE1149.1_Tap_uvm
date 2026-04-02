module sib #(
    parameter WIDTH = 1  // usually 1-bit SIB enable
)(
    input  logic tck,
    input  logic trst_n,
    input  logic tdi,
    input  logic tms,
    output logic tdo,

    input  logic shift_dr,
    input  logic capture_dr,
    input  logic update_dr,

    // downstream chain
    input  logic child_tdo,
    output logic child_tdi,

    output logic sib_bit  // current enable state
);

    // ---------------------------
    // Temporary shift register
    // ---------------------------
    logic [WIDTH-1:0] shift_reg;

    // ---------------------------
    // Shift/Capture
    // ---------------------------
    always_ff @(posedge tck or negedge trst_n) begin
        if (!trst_n) begin
            shift_reg <= '0;
        end else if (capture_dr) begin
            // preload with current enable
            shift_reg <= sib_bit;
        end else if (shift_dr && !tms) begin
            // shift in TDI (works for WIDTH=1)
          if(WIDTH == 1)
            shift_reg <= tdi;
            else
            shift_reg <= {tdi, shift_reg[WIDTH-1:1]};
        end
    end

    // ---------------------------
    // Latch enable on UPDATE_DR
    // ---------------------------
    always_ff @(posedge tck or negedge trst_n) begin
        if (!trst_n)
            sib_bit <= 1'b0;
        else if (update_dr)
            sib_bit <= shift_reg;
    end

    // ---------------------------
    // Pass TDI downstream only when SIB enabled
    // ---------------------------
    assign child_tdi = sib_bit ? shift_reg[0] : 1'b0;

    // ---------------------------
    // TDO mux
    // ---------------------------
  assign tdo = sib_bit ? child_tdo : shift_reg[0];

endmodule 
