module sib #(
    parameter WIDTH = 8   // width of instrument data
)(
    input  logic tck,
    input  logic trst_n,
    input  logic tdi_in,
    output logic tdo_out,
    input  logic [WIDTH-1:0] instr_data_in = '0,
    output logic [WIDTH-1:0] instr_data_out
);

    // --------------------------
    // Internal shift register: [enable_bit | data_bits]
    // --------------------------
    logic [WIDTH:0] shift_reg;  // MSB is SIB enable

    // Capture initial state on reset
    always_ff @(posedge tck or negedge trst_n) begin
        if (!trst_n) begin
            shift_reg <= {1'b0, instr_data_in};
            tdo_out   <= 1'b0;
        end else begin
            // Shift serially
            tdo_out   <= shift_reg[WIDTH];                // output MSB first
            shift_reg <= {shift_reg[WIDTH-1:0], tdi_in}; // shift in TDI at LSB
        end
    end

    // SIB enable is now the MSB of shift_reg
    wire sib_enable = shift_reg[WIDTH];

    // Instrument data is the remaining bits
    assign instr_data_out = shift_reg[WIDTH-1:0];

endmodule
