module dummy_mbist #(parameter WIDTH = 16) (
    input  logic tck,
    input  logic trst_n,
    input  logic tdi_in,
    output logic tdo_out
);
    // Simple shift register to simulate MBIST
    logic [WIDTH-1:0] shift_reg;

    always_ff @(posedge tck or negedge trst_n) begin
        if (!trst_n) begin
            shift_reg <= '0;
            tdo_out   <= 0;
        end else begin
            tdo_out   <= shift_reg[WIDTH-1];
            shift_reg <= {shift_reg[WIDTH-2:0], tdi_in};
        end
    end
endmodule
