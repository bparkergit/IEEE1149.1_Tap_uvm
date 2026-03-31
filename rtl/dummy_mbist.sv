module dummy_mbist #(
    parameter WIDTH = 16
)(
    input  logic tck,
    input  logic trst_n,
    input  logic tdi_in,      // serial input from previous instrument
    output logic tdo_out,     // serial output to next in chain
	input	logic enable
);

    // ---------------------------
    // Shift register for MBIST
    // ---------------------------
    logic [WIDTH-1:0] shift_reg;

    always_ff @(posedge tck or negedge trst_n) begin
        if (!trst_n)
            shift_reg <= '0;
      else if(enable)
            shift_reg <= {tdi_in, shift_reg[WIDTH-1:1]};
    end

    // ---------------------------
    // TDO comes from LSB of shift register
    // ---------------------------
    assign tdo_out = shift_reg[0];

endmodule
