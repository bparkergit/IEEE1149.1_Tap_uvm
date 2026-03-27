module ijtag_bus #(
    parameter NUM_INSTR = 2,
    parameter MAX_WIDTH = 32
)(
    input  logic tck,
    input  logic trst_n,
    input  logic tdi_in,
    output logic tdo_out,
    output logic [NUM_INSTR-1:0][MAX_WIDTH-1:0] instrument_shift_reg
);

    logic tdo_chain;

    // simple serial chain through instruments
    assign tdo_chain = instrument_shift_reg[NUM_INSTR-1][0];
    assign tdo_out   = tdo_chain;

    always_ff @(posedge tck or negedge trst_n) begin
        if (!trst_n) begin
            instrument_shift_reg <= '{default:'0};
        end else begin
            instrument_shift_reg[0] <= {tdi_in, instrument_shift_reg[0][MAX_WIDTH-1:1]};
            for (int i=1; i<NUM_INSTR; i++)
                instrument_shift_reg[i] <= {instrument_shift_reg[i-1][0], instrument_shift_reg[i][MAX_WIDTH-1:1]};
        end
    end

endmodule
