module dummy_mbist #(
    parameter WIDTH = 16
)(
    input  logic tck,
    input  logic trst_n,
    input  logic tdi_in,
    output logic tdo_out
);

    // Just passes input to output (dummy)
    logic [WIDTH-1:0] shift_reg;

    always_ff @(posedge tck or negedge trst_n) begin
        if (!trst_n) shift_reg <= '0;
        else shift_reg <= {tdi_in, shift_reg[WIDTH-1:1]};
    end

    assign tdo_out = shift_reg[0];

endmodule
