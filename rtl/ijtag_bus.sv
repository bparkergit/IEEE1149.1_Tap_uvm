module ijtag_bus #(
    parameter INSTR_SHIFT_WIDTH = 32
)(
    input  logic tck,
    input  logic trst_n,
    input  logic tdi_in,               // TAP TDO in
    output logic tdo_out,              // chain TDO out

    // separate shift registers for each instrument
    inout logic [INSTR_SHIFT_WIDTH-1:0] bisr_shift_reg,
    inout logic [INSTR_SHIFT_WIDTH-1:0] mbist_shift_reg
);

    // ---------------------------
    // Serial chaining logic
    // ---------------------------
    always_ff @(posedge tck or negedge trst_n) begin
        if (!trst_n) begin
            bisr_shift_reg   <= '0;
            mbist_shift_reg  <= '0;
        end else begin
            // shift BISR first
            bisr_shift_reg <= {tdi_in, bisr_shift_reg[INSTR_SHIFT_WIDTH-1:1]};
            // shift MBIST, LSB gets BISR's LSB
            mbist_shift_reg <= {bisr_shift_reg[0], mbist_shift_reg[INSTR_SHIFT_WIDTH-1:1]};
        end
    end

    // ---------------------------
    // TDO output comes from last instrument in chain
    // ---------------------------
    assign tdo_out = mbist_shift_reg[0];

endmodule
