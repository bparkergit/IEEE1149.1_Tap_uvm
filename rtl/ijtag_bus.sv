module ijtag_bus #(
    parameter NUM_INSTR = 2,
    parameter MAX_WIDTH = 32
)(
    input  logic tck,
    input  logic trst_n,
    input  logic tdi_in,
    output logic tdo_out
);

    logic [NUM_INSTR-1:0][MAX_WIDTH-1:0] shift_regs;
    logic tdo_chain;

    // simple serial chain through instruments
    assign tdo_chain = shift_regs[NUM_INSTR-1][0];
    assign tdo_out = tdo_chain;

    always_ff @(posedge tck or negedge trst_n) begin
        if (!trst_n) begin
            shift_regs <= '{default:'0};
        end else begin
            shift_regs[0] <= {tdi_in, shift_regs[0][MAX_WIDTH-1:1]};
            for (int i=1; i<NUM_INSTR; i++)
                shift_regs[i] <= {shift_regs[i-1][0], shift_regs[i][MAX_WIDTH-1:1]};
        end
    end

endmodule
